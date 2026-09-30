import 'dart:math';
import '../models/models.dart';

class GroupService {
  /// Returns the next calendar due date for a contribution.
  ///
  /// Contribution dates follow the selected frequency rather than the date the
  /// group was created: daily is today/tomorrow, weekly is Monday, and monthly
  /// is the first day of the month.
  static DateTime nextContributionDate(
    SavingsGroup group,
    DateTime now, {
    required bool currentContributionPaid,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    if (group.frequency == 'Daily') {
      return currentContributionPaid
          ? today.add(const Duration(days: 1))
          : today;
    }
    if (group.frequency == 'Weekly') {
      var daysUntilMonday = DateTime.monday - today.weekday;
      if (daysUntilMonday < 0) daysUntilMonday += 7;
      if (daysUntilMonday == 0 && currentContributionPaid) {
        daysUntilMonday = 7;
      }
      return today.add(Duration(days: daysUntilMonday));
    }
    if (group.frequency == 'Biweekly') {
      // Keep biweekly groups anchored to their configured start date.
      final elapsedDays = today
          .difference(
            DateTime(
              group.startDate.year,
              group.startDate.month,
              group.startDate.day,
            ),
          )
          .inDays;
      final periodsElapsed = elapsedDays <= 0 ? 0 : elapsedDays ~/ 14;
      final due = DateTime(
        group.startDate.year,
        group.startDate.month,
        group.startDate.day,
      ).add(Duration(days: periodsElapsed * 14));
      return due == today && !currentContributionPaid
          ? due
          : due.add(const Duration(days: 14));
    }

    // Monthly contributions are due on the first. Once that contribution has
    // been made, or the first has passed, use the first of the next month.
    if (today.day == 1 && !currentContributionPaid) return today;
    return DateTime(today.year, today.month + 1, 1);
  }

  static DateTime cycleDate(SavingsGroup group, int cycle) {
    final offset = cycle - 1;
    if (group.frequency == 'Daily') {
      return group.startDate.add(Duration(days: offset));
    }
    if (group.frequency == 'Weekly') {
      return group.startDate.add(Duration(days: offset * 7));
    }
    if (group.frequency == 'Biweekly') {
      return group.startDate.add(Duration(days: offset * 14));
    }
    final monthIndex = group.startDate.month + offset;
    final target = DateTime(group.startDate.year, monthIndex + 1, 0).day;
    return DateTime(
      group.startDate.year,
      monthIndex,
      min(group.startDate.day, target),
    );
  }

  static GroupMember? recipient(List<GroupMember> members, int cycle) {
    if (members.isEmpty || cycle < 1) return null;
    final ordered = [...members]
      ..sort((a, b) => a.payoutPosition.compareTo(b.payoutPosition));
    return ordered[(cycle - 1) % ordered.length];
  }

  static int balance(Iterable<Contribution> contributions, int cycle) =>
      contributions
          .where((c) => c.cycle == cycle && c.status == 'Paid')
          .fold(0, (sum, c) => sum + c.amountKobo);
  static double progress(int balance, int expected) =>
      expected <= 0 ? 0 : (balance / expected).clamp(0, 1);
  static bool isComplete(Iterable<Payout> payouts, int cycle) =>
      payouts.any((p) => p.cycle == cycle && p.status == 'Completed');
  static String inviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return 'AJO-${List.generate(5, (_) => chars[random.nextInt(chars.length)]).join()}';
  }
}
