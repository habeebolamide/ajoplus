import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'payment_screen.dart';

class ContributionsScreen extends StatelessWidget {
  final String groupId;
  const ContributionsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final group = app.group(groupId);
    final user = context.watch<AuthProvider>().user!;
    final rows = app.groupContributions(groupId, cycle: group.currentCycle);
    final own = app.ownContribution(group, user.id);
    final history = app.groupContributions(groupId)
      ..sort((a, b) => b.cycle.compareTo(a.cycle));
    return Scaffold(
      appBar: AppBar(title: const Text('Contributions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MetricCard(
            'Cycle balance',
            '${money(app.balance(group))} / ${money(app.expected(group))}',
            detail:
                '${rows.where((row) => row.status == 'Paid').length} of ${rows.length} paid',
          ),
          if (own != null && own.status != 'Paid') ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      PaymentScreen(groupId: groupId, contributionId: own.id),
                ),
              ),
              icon: const Icon(Icons.payment),
              label: const Text('Pay Contribution'),
            ),
          ],
          const SectionTitle('Current cycle'),
          ...rows.map(
            (row) => Card(
              child: ListTile(
                title: Text(row.memberName),
                subtitle: Text(money(row.amountKobo)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusChip(row.status),
                    if (row.status != 'Paid' && group.creatorId == user.id)
                      IconButton(
                        tooltip: 'Record demo payment',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => PaymentScreen(
                              groupId: groupId,
                              contributionId: row.id,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SectionTitle('Contribution history'),
          ...history.map(
            (row) => Card(
              child: ListTile(
                title: Text('${row.memberName} · Cycle ${row.cycle}'),
                subtitle: Text(
                  row.paidAt == null
                      ? 'Not paid'
                      : '${shortDate(row.paidAt!)} · ${row.paymentReference}',
                ),
                trailing: StatusChip(row.status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
