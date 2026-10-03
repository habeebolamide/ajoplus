import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';

class MembersScreen extends StatelessWidget {
  final String groupId;
  const MembersScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final group = app.group(groupId);
    final members = app.groupMembers(groupId);
    final cycle = group.isComplete ? group.totalCycles : group.currentCycle;
    final rows = app.groupContributions(groupId, cycle: cycle);
    final due = GroupService.cycleDate(group, cycle);
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${members.length} of ${group.maxMembers} members',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...members.map((member) {
            final matching = rows.where((row) => row.memberId == member.id);
            final paid = matching.any((row) => row.status == 'Paid');
            final status = group.isComplete
                ? 'Completed'
                : paid
                ? 'Paid'
                : due.isBefore(DateTime.now())
                ? 'Overdue'
                : 'Pending';
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(member.name.characters.first),
                ),
                title: Text(member.name),
                subtitle: Text(
                  group.isSavings
                      ? 'Repaid after the savings period'
                      : 'Payout position ${member.payoutPosition}',
                ),
                trailing: StatusChip(status),
              ),
            );
          }),
        ],
      ),
    );
  }
}
