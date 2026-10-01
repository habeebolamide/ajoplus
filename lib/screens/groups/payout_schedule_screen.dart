import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/formatters.dart';
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
    final schedule = app.schedule
        .where((item) => item.groupId == groupId)
        .toList();
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
            final entries = schedule.where((item) => item.cycle == cycle);
            final entry = entries.isEmpty ? null : entries.first;
            final status = entry?.status == 'completed'
                ? 'Completed'
                : app.payouts.any(
                    (p) =>
                        p.groupId == groupId &&
                        p.cycle == cycle &&
                        p.status == 'Pending',
                  )
                ? 'Pending settlement'
                : cycle == group.currentCycle
                ? 'Upcoming'
                : 'Scheduled';
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('$cycle')),
                title: Text(entry?.recipientName ?? 'Awaiting member'),
                subtitle: Text(
                  'Cycle $cycle · ${shortDate(entry?.scheduledFor ?? GroupService.cycleDate(group, cycle))}',
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
