import 'dart:math';
import '../models/models.dart';

class GroupService {
  static DateTime cycleDate(SavingsGroup group, int cycle) =>
      dateForCycle(group.startDate, group.frequency, cycle);

  static DateTime dateForCycle(
    DateTime startDate,
    String frequency,
    int cycle,
  ) {
    final offset = cycle - 1;
    if (frequency == 'Daily') {
      return startDate.add(Duration(days: offset));
    }
    if (frequency == 'Weekly') {
      return startDate.add(Duration(days: offset * 7));
    }
    if (frequency == 'Biweekly') {
      return startDate.add(Duration(days: offset * 14));
    }
    final monthIndex = startDate.month + offset;
    final target = DateTime(startDate.year, monthIndex + 1, 0).day;
    return DateTime(startDate.year, monthIndex, min(startDate.day, target));
  }

  static DateTime maturityDate(SavingsGroup group) =>
      cycleDate(group, group.totalCycles + 1);

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
}
