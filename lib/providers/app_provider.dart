import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../models/app_transaction.dart';
import '../models/app_user.dart';
import '../models/contribution.dart';
import '../models/group_member.dart';
import '../models/group_preview.dart';
import '../models/payout.dart';
import '../models/payout_schedule_entry.dart';
import '../models/savings_group.dart';
import '../services/api_client.dart';
import '../services/api_data.dart';
import '../services/group_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiClient api;
  final NotificationService notificationService;
  AppProvider({required this.api, NotificationService? notificationService})
      : notificationService = notificationService ?? NotificationService();

  List<SavingsGroup> groups = [];
  List<GroupMember> members = [];
  List<Contribution> contributions = [];
  List<Payout> payouts = [];
  List<PayoutScheduleEntry> schedule = [];
  List<AppTransaction> transactions = [];
  List<AppNotification> notifications = [];
  bool loading = false;
  String? loadError;
  Future<void>? _refreshing;

  Future<List<Object?>> _pages(String path) async {
    final result = <Object?>[];
    for (var page = 1; ; page++) {
      final separator = path.contains('?') ? '&' : '?';
      final response = ApiData.object(await api.get('$path${separator}page=$page'));
      result.addAll(ApiData.array(response['data']));
      final lastPage = ApiData.integer(response, 'last_page');
      if (page >= lastPage) return result;
    }
  }

  Future<void> refresh() => _refreshing ??= _load().whenComplete(() => _refreshing = null);

  Future<void> _load() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      final loadedGroups = (await _pages('groups')).map(SavingsGroup.fromApi).toList();
      final details = await Future.wait(loadedGroups.map((group) => api.get('groups/${group.id}')));
      final loadedMembers = <GroupMember>[];
      final loadedPayouts = <Payout>[];
      for (final raw in details) {
        final detail = ApiData.object(raw);
        loadedMembers.addAll(ApiData.array(detail['members']).map(GroupMember.fromApi));
        loadedPayouts.addAll(ApiData.array(detail['payouts']).map(Payout.fromApi));
      }
      final scheduleResponses = await Future.wait(
          loadedGroups.map((group) => api.get('groups/${group.id}/schedule')));
      final loadedSchedule = <PayoutScheduleEntry>[];
      for (var index = 0; index < loadedGroups.length; index++) {
        final response = ApiData.object(scheduleResponses[index]);
        loadedSchedule.addAll(ApiData.array(response['data']).map(
            (raw) => PayoutScheduleEntry.fromApi(loadedGroups[index].id, raw)));
      }
      final memberNames = {for (final member in loadedMembers) member.id: member.name};
      final pages = await Future.wait(loadedGroups.map((group) => _pages('groups/${group.id}/contributions')));
      final loadedContributions = pages.expand((page) => page).map((raw) {
        final data = ApiData.object(raw);
        final name = memberNames[ApiData.id(data, 'member_id')];
        if (name == null) throw const ApiException('The server returned an unknown member.');
        return Contribution.fromApi(data, name);
      }).toList();
      final otherRows = await Future.wait([_pages('transactions'), _pages('notifications')]);
      final loadedTransactions = otherRows[0].map((raw) {
        final data = ApiData.object(raw);
        final name = memberNames[ApiData.id(data, 'member_id')];
        if (name == null) throw const ApiException('The server returned an unknown member.');
        return AppTransaction.fromApi(data, name);
      }).toList();
      final loadedNotifications = otherRows[1].map(AppNotification.fromApi).toList();
      groups = loadedGroups;
      members = loadedMembers;
      contributions = loadedContributions;
      payouts = loadedPayouts;
      schedule = loadedSchedule;
      transactions = loadedTransactions;
      notifications = loadedNotifications;
    } catch (error) {
      loadError = error is ApiException ? error.message : 'Could not load your data. Please retry.';
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    groups = [];
    members = [];
    contributions = [];
    payouts = [];
    schedule = [];
    transactions = [];
    notifications = [];
    loadError = null;
    notifyListeners();
  }

  SavingsGroup group(String id) => groups.firstWhere((g) => g.id == id);
  List<GroupMember> groupMembers(String id) => (members.where((m) => m.groupId == id).toList()
    ..sort((a, b) => a.payoutPosition.compareTo(b.payoutPosition)));
  List<Contribution> groupContributions(String id, {int? cycle}) =>
      contributions.where((c) => c.groupId == id && (cycle == null || c.cycle == cycle)).toList();
  List<AppTransaction> myTransactions(String userId) => transactions;
  List<AppNotification> myNotifications(String userId) => notifications;
  bool isMember(String groupId, String userId) => members.any((m) => m.groupId == groupId && m.userId == userId);
  List<SavingsGroup> myGroups(String userId) => groups;
  int balance(SavingsGroup group) => GroupService.balance(groupContributions(group.id), group.currentCycle);
  int expected(SavingsGroup group) => group.contributionAmountKobo * group.maxMembers;
  GroupMember? recipient(SavingsGroup group, [int? cycle]) =>
      GroupService.recipient(groupMembers(group.id), cycle ?? group.currentCycle);

  Contribution? ownContribution(SavingsGroup group, String userId) {
    final own = groupMembers(group.id).where((m) => m.userId == userId);
    if (own.isEmpty) return null;
    final rows = groupContributions(group.id, cycle: group.currentCycle).where((c) => c.memberId == own.first.id);
    return rows.isEmpty ? null : rows.first;
  }

  ({SavingsGroup group, int cycle, DateTime dueDate})? nextContribution(String userId, DateTime today) {
    final upcoming = <({SavingsGroup group, int cycle, DateTime dueDate})>[];
    for (final group in groups) {
      final currentPaid = ownContribution(group, userId)?.status == 'Paid';
      final cycle = currentPaid ? group.currentCycle + 1 : group.currentCycle;
      if (cycle > group.maxMembers) continue;
      upcoming.add((group: group, cycle: cycle, dueDate: GroupService.cycleDate(group, cycle)));
    }
    upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return upcoming.firstOrNull;
  }

  Future<SavingsGroup> createGroup({
    required AppUser user,
    required String name,
    required String description,
    required int amountKobo,
    required String frequency,
    required int maxMembers,
    required DateTime startDate,
  }) async {
    final date = '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final raw = await api.post('groups', {
      'name': name.trim(),
      'description': description.trim(),
      'contribution_amount_kobo': amountKobo,
      'frequency': frequency.toLowerCase(),
      'max_members': maxMembers,
      'start_date': date,
    });
    final created = SavingsGroup.fromApi(raw);
    await refresh();
    return created;
  }

  Future<GroupPreview> lookup(String code) async =>
      GroupPreview.fromApi(await api.post('groups/lookup', {'invite_code': code.trim().toUpperCase()}));

  Future<void> join(String code) async {
    await api.post('groups/join', {'invite_code': code.trim().toUpperCase()});
    await refresh();
  }

  Future<Uri> checkout(SavingsGroup group, Contribution contribution) async {
    final response = ApiData.object(await api.post('groups/${group.id}/contributions/${contribution.id}/checkout'));
    final uri = Uri.tryParse(ApiData.string(response, 'authorization_url'));
    if (uri == null || uri.scheme != 'https' || uri.host != 'checkout.paystack.com') {
      throw const ApiException('The payment provider returned an invalid checkout link.');
    }
    return uri;
  }

  Future<Contribution> verifyPayment(SavingsGroup group, Contribution contribution) async {
    final data = ApiData.object(await api.post('groups/${group.id}/contributions/${contribution.id}/verify'));
    final verified = Contribution.fromApi(data, contribution.memberName);
    await refresh();
    return verified;
  }

  bool canComplete(SavingsGroup group) {
    final people = groupMembers(group.id);
    final rows = groupContributions(group.id, cycle: group.currentCycle);
    return people.length == group.maxMembers &&
        !payouts.any((p) => p.groupId == group.id && p.cycle == group.currentCycle) &&
        people.every((m) => rows.any((c) => c.memberId == m.id && c.status == 'Paid'));
  }

  bool hasPendingPayout(SavingsGroup group) =>
      payouts.any((p) => p.groupId == group.id && p.cycle == group.currentCycle && p.status == 'Pending');

  Future<void> preparePayout(SavingsGroup group) async {
    await api.post('groups/${group.id}/complete-cycle');
    await refresh();
  }

  Future<void> settlePayout(SavingsGroup group, String reference) async {
    await api.post('groups/${group.id}/settle-payout', {'reference': reference.trim()});
    await refresh();
  }

  Future<void> readNotification(AppNotification notification) async {
    await api.patch('notifications/${notification.id}/read');
    await refresh();
  }

  Future<void> refreshReminders(String userId) async {
    await notificationService.cancelScheduled();
    if (!(StorageService.prefs.getBool('reminders') ?? true)) return;
    final now = DateTime.now();
    for (final group in groups) {
      if (group.currentCycle > group.maxMembers || ownContribution(group, userId)?.status == 'Paid') continue;
      final due = GroupService.cycleDate(group, group.currentCycle);
      final reminderKey = '${group.id}-${group.currentCycle}';
      int reminderId(String kind) => '$reminderKey-$kind'.codeUnits.fold<int>(
          0, (value, code) => (value * 31 + code) & 0x7fffffff);
      for (final (kind, scheduledAt, message) in [
        ('before', DateTime(due.year, due.month, due.day - 1, 9), 'Your contribution to ${group.name} is due tomorrow.'),
        ('due', DateTime(due.year, due.month, due.day, 9), 'Your contribution to ${group.name} is due today.'),
      ]) {
        if (scheduledAt.isAfter(now)) {
          await notificationService.schedule(reminderId(kind), scheduledAt, 'Contribution reminder', message);
        }
      }
    }
  }
}
