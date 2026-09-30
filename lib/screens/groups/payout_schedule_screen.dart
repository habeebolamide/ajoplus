import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';

class PayoutScheduleScreen extends StatelessWidget {
  final String groupId;
  const PayoutScheduleScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final group = app.group(groupId);
    final members = app.groupMembers(groupId);
    return Scaffold(
      appBar: AppBar(title: const Text('Payout schedule')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Payout order is fixed when members join. Dates follow the group frequency.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...List.generate(group.maxMembers, (index) {
            final cycle = index + 1;
            final recipient = GroupService.recipient(members, cycle);
            final status =
                app.payouts.any(
                  (p) =>
                      p.groupId == groupId &&
                      p.cycle == cycle &&
                      p.status == 'Completed',
                )
                ? 'Completed'
                : cycle == group.currentCycle
                ? 'Upcoming'
                : 'Scheduled';
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('$cycle')),
                title: Text(recipient?.name ?? 'Awaiting member'),
                subtitle: Text(
                  'Cycle $cycle · ${shortDate(GroupService.cycleDate(group, cycle))}',
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
