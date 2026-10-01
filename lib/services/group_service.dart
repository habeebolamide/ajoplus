import 'dart:math';
import '../models/models.dart';

class GroupService {
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
}
