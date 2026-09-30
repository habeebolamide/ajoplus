import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class AppProvider extends ChangeNotifier {
  final PaymentService paymentService;
  final NotificationService notificationService;
  late List<SavingsGroup> groups;
  late List<GroupMember> members;
  late List<Contribution> contributions;
  late List<Payout> payouts;
  late List<AppTransaction> transactions;
  late List<AppNotification> notifications;
  bool busy = false;
  AppProvider({
    PaymentService? paymentService,
    NotificationService? notificationService,
  }) : paymentService = paymentService ?? PaymentService(),
       notificationService = notificationService ?? NotificationService() {
    reload();
    this.notificationService.init();
  }
  void reload() {
    groups = StorageService.read(StorageService.groups, SavingsGroup.from);
    members = StorageService.read(StorageService.members, GroupMember.from);
    contributions = StorageService.read(
      StorageService.contributions,
      Contribution.from,
    );
    payouts = StorageService.read(StorageService.payouts, Payout.from);
    transactions = StorageService.read(
      StorageService.transactions,
      AppTransaction.from,
    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifications = StorageService.read(
      StorageService.notifications,
      AppNotification.from,
    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  SavingsGroup group(String id) => groups.firstWhere((g) => g.id == id);
  List<GroupMember> groupMembers(String id) =>
      (members.where((m) => m.groupId == id).toList()
        ..sort((a, b) => a.payoutPosition.compareTo(b.payoutPosition)));
  List<Contribution> groupContributions(String id, {int? cycle}) =>
      contributions
          .where((c) => c.groupId == id && (cycle == null || c.cycle == cycle))
          .toList();
  List<AppTransaction> groupTransactions(String id) =>
      transactions.where((t) => t.groupId == id).toList();
  bool isMember(String groupId, String userId) =>
      members.any((m) => m.groupId == groupId && m.userId == userId);
  List<SavingsGroup> myGroups(String userId) =>
      groups.where((g) => isMember(g.id, userId)).toList();
  int balance(SavingsGroup group) =>
      GroupService.balance(groupContributions(group.id), group.currentCycle);
  int expected(SavingsGroup group) =>
      group.contributionAmountKobo * group.maxMembers;
  GroupMember? recipient(SavingsGroup group, [int? cycle]) =>
      GroupService.recipient(
        groupMembers(group.id),
        cycle ?? group.currentCycle,
      );
  Contribution? ownContribution(SavingsGroup group, String userId) {
    final own = groupMembers(group.id).where((m) => m.userId == userId);
    if (own.isEmpty) return null;
    final rows = groupContributions(
      group.id,
      cycle: group.currentCycle,
    ).where((c) => c.memberId == own.first.id);
    return rows.isEmpty ? null : rows.first;
  }

  ({SavingsGroup group, int cycle, DateTime dueDate})? nextContribution(
    String userId,
    DateTime today,
  ) {
    final upcoming = <({SavingsGroup group, int cycle, DateTime dueDate})>[];

    for (final group in myGroups(userId)) {
      if (group.currentCycle > group.maxMembers) continue;
      final currentPaid = ownContribution(group, userId)?.status == 'Paid';
      final cycle = currentPaid ? group.currentCycle + 1 : group.currentCycle;
      if (cycle > group.maxMembers) continue;
      upcoming.add((
        group: group,
        cycle: cycle,
        dueDate: GroupService.nextContributionDate(
          group,
          today,
          currentContributionPaid: currentPaid,
        ),
      ));
    }

    upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return upcoming.isEmpty ? null : upcoming.first;
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
    if (amountKobo <= 0 || maxMembers < 2) {
      throw StateError('Enter a positive amount and at least 2 members.');
    }
    final now = DateTime.now();
    final group = SavingsGroup(
      id: newId(),
      name: name.trim(),
      description: description.trim(),
      creatorId: user.id,
      contributionAmountKobo: amountKobo,
      frequency: frequency,
      maxMembers: maxMembers,
      startDate: startDate,
      inviteCode: GroupService.inviteCode(),
      currentCycle: 1,
      createdAt: now,
    );
    final member = GroupMember(
      newId(),
      group.id,
      user.id,
      user.fullName,
      1,
      now,
    );
    final contribution = Contribution(
      newId(),
      group.id,
      member.id,
      member.name,
      1,
      amountKobo,
      'Pending',
      '',
      null,
    );
    await StorageService.groups.put(group.id, group.toMap());
    await StorageService.members.put(member.id, member.toMap());
    await StorageService.contributions.put(
      contribution.id,
      contribution.toMap(),
    );
    reload();
    return group;
  }

  SavingsGroup? findInvite(String code) {
    final normalized = code.trim().toUpperCase();
    for (final group in groups) {
      if (group.inviteCode == normalized) return group;
    }
    return null;
  }

  Future<void> join(SavingsGroup group, AppUser user) async {
    if (group.currentCycle > 1) {
      throw StateError('This group has started its payout rotation.');
    }
    if (isMember(group.id, user.id)) {
      throw StateError('You have already joined this group.');
    }
    final existing = groupMembers(group.id);
    if (existing.length >= group.maxMembers) {
      throw StateError('This group is full.');
    }
    final member = GroupMember(
      newId(),
      group.id,
      user.id,
      user.fullName,
      existing.length + 1,
      DateTime.now(),
    );
    await StorageService.members.put(member.id, member.toMap());
    final contribution = Contribution(
      newId(),
      group.id,
      member.id,
      member.name,
      group.currentCycle,
      group.contributionAmountKobo,
      'Pending',
      '',
      null,
    );
    await StorageService.contributions.put(
      contribution.id,
      contribution.toMap(),
    );
    await addNotification(
      'Group joined',
      'You joined ${group.name}. Your payout position is ${member.payoutPosition}.',
      'group',
    );
    reload();
  }

  Future<String> pay(
    SavingsGroup group,
    Contribution contribution, {
    required bool succeed,
  }) async {
    if (busy) throw StateError('A payment is already processing.');
    if (contribution.status == 'Paid') {
      throw StateError('This contribution has already been paid.');
    }
    busy = true;
    notifyListeners();
    try {
      late final String reference;
      try {
        reference = await paymentService.simulate(succeed: succeed);
      } catch (_) {
        await StorageService.contributions.put(
          contribution.id,
          contribution.failed().toMap(),
        );
        final failed = AppTransaction(
          newId(),
          group.id,
          contribution.memberId,
          contribution.memberName,
          group.name,
          'Contribution',
          contribution.amountKobo,
          'Failed',
          'AJO-FAIL-${DateTime.now().millisecondsSinceEpoch}',
          DateTime.now(),
        );
        await StorageService.transactions.put(failed.id, failed.toMap());
        rethrow;
      }
      final paid = contribution.paid(reference);
      await StorageService.contributions.put(paid.id, paid.toMap());
      final tx = AppTransaction(
        newId(),
        group.id,
        contribution.memberId,
        contribution.memberName,
        group.name,
        'Contribution',
        contribution.amountKobo,
        'Successful',
        reference,
        DateTime.now(),
      );
      await StorageService.transactions.put(tx.id, tx.toMap());
      await addNotification(
        'Contribution received',
        '${contribution.memberName} paid ${money(contribution.amountKobo)} to ${group.name}.',
        'contribution',
      );
      return reference;
    } finally {
      busy = false;
      reload();
    }
  }

  bool canComplete(SavingsGroup group) {
    final people = groupMembers(group.id);
    final rows = groupContributions(group.id, cycle: group.currentCycle);
    return people.length == group.maxMembers &&
        people.every(
          (m) => rows.any((c) => c.memberId == m.id && c.status == 'Paid'),
        );
  }

  Future<void> completeCycle(SavingsGroup group, AppUser user) async {
    if (group.creatorId != user.id) {
      throw StateError('Only the group organizer can complete a cycle.');
    }
    if (group.currentCycle > group.maxMembers) {
      throw StateError('All group cycles are complete.');
    }
    if (!canComplete(group)) {
      throw StateError(
        'All member slots must be filled and every contribution paid first.',
      );
    }
    if (GroupService.isComplete(
      payouts.where((p) => p.groupId == group.id),
      group.currentCycle,
    )) {
      throw StateError('This cycle was already completed.');
    }
    final receiver = recipient(group)!;
    final amountKobo = balance(group);
    final now = DateTime.now();
    final payout = Payout(
      newId(),
      group.id,
      receiver.id,
      group.currentCycle,
      amountKobo,
      GroupService.cycleDate(group, group.currentCycle),
      'Completed',
      now,
    );
    await StorageService.payouts.put(payout.id, payout.toMap());
    final tx = AppTransaction(
      newId(),
      group.id,
      receiver.id,
      receiver.name,
      group.name,
      'Payout',
      amountKobo,
      'Successful',
      'AJO-OUT-${now.millisecondsSinceEpoch}',
      now,
    );
    await StorageService.transactions.put(tx.id, tx.toMap());
    if (group.currentCycle < group.maxMembers) {
      final next = group.currentCycle + 1;
      await StorageService.groups.put(group.id, group.withCycle(next).toMap());
      for (final member in groupMembers(group.id)) {
        final row = Contribution(
          newId(),
          group.id,
          member.id,
          member.name,
          next,
          group.contributionAmountKobo,
          'Pending',
          '',
          null,
        );
        await StorageService.contributions.put(row.id, row.toMap());
      }
    } else {
      await StorageService.groups.put(
        group.id,
        group.withCycle(group.maxMembers + 1).toMap(),
      );
    }
    await addNotification(
      'Payout completed',
      '${receiver.name} received ${money(amountKobo)} from ${group.name}.',
      'payout',
    );
    reload();
  }

  Future<void> addNotification(
    String title,
    String message,
    String type,
  ) async {
    final row = AppNotification(
      newId(),
      title,
      message,
      type,
      DateTime.now(),
      false,
    );
    await StorageService.notifications.put(row.id, row.toMap());
    unawaited(notificationService.show(title, message));
    reload();
  }

  Future<void> readNotification(AppNotification notification) async {
    await StorageService.notifications.put(
      notification.id,
      notification.read().toMap(),
    );
    reload();
  }

  Future<void> refreshReminders(String userId) async {
    await notificationService.cancelScheduled();
    if (!(StorageService.prefs.getBool('reminders') ?? true)) return;
    final today = DateTime.now();
    for (final group in myGroups(userId)) {
      if (group.currentCycle > group.maxMembers) continue;
      final due = GroupService.cycleDate(group, group.currentCycle);
      final dayBefore = DateTime(due.year, due.month, due.day - 1, 9);
      final dueMorning = DateTime(due.year, due.month, due.day, 9);
      final overdueMorning = DateTime(due.year, due.month, due.day + 1, 9);
      final reminderKey = '${group.id}-${group.currentCycle}';
      int reminderId(String kind) => '$reminderKey-$kind'.codeUnits.fold<int>(
        0,
        (value, code) => (value * 31 + code) & 0x7fffffff,
      );
      final days = DateTime(
        due.year,
        due.month,
        due.day,
      ).difference(DateTime(today.year, today.month, today.day)).inDays;
      final own = ownContribution(group, userId);
      if (own != null && own.status != 'Paid') {
        await notificationService.schedule(
          reminderId('tomorrow'),
          dayBefore,
          'Contribution due tomorrow',
          'Your ${money(group.contributionAmountKobo)} contribution to ${group.name} is due tomorrow.',
        );
        await notificationService.schedule(
          reminderId('today'),
          dueMorning,
          'Contribution due today',
          'Your ${money(group.contributionAmountKobo)} contribution to ${group.name} is due today.',
        );
        await notificationService.schedule(
          reminderId('overdue'),
          overdueMorning,
          'Contribution overdue',
          'Your contribution to ${group.name} is overdue.',
        );
      }
      await notificationService.schedule(
        reminderId('payout'),
        dayBefore,
        'Payout tomorrow',
        '${recipient(group)?.name ?? 'A member'} receives the ${group.name} payout tomorrow.',
      );
      String? message;
      if (own != null && own.status != 'Paid') {
        if (days == 1) {
          message =
              'Your ${money(group.contributionAmountKobo)} contribution to ${group.name} is due tomorrow.';
        }
        if (days == 0) {
          message =
              'Your ${money(group.contributionAmountKobo)} contribution to ${group.name} is due today.';
        }
        if (days < 0) {
          message = 'Your contribution to ${group.name} is overdue.';
        }
      }
      if (message == null && days == 1) {
        message =
            '${recipient(group)?.name ?? 'A member'} receives the ${group.name} payout tomorrow.';
      }
      if (message == null) continue;
      final key =
          'reminder-${group.id}-${group.currentCycle}-${reminderId(message)}';
      if (StorageService.notifications.containsKey(key)) continue;
      final row = AppNotification(
        key,
        'AjoPlus reminder',
        message,
        'reminder',
        today,
        false,
      );
      await StorageService.notifications.put(key, row.toMap());
      await notificationService.show(row.title, row.message);
    }
    reload();
  }
}
