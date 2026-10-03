import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/formatters.dart';
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
    final rows = app.groupContributions(
      groupId,
      cycle: group.isComplete ? group.totalCycles : group.currentCycle,
    );
    final own = app.ownContribution(group, user.id);
    final history = app.groupContributions(groupId)
      ..sort((a, b) => b.cycle.compareTo(a.cycle));
    return Scaffold(
      appBar: AppBar(title: const Text('Contributions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MetricCard(
            group.isSavings ? 'Total saved' : 'Cycle balance',
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
          SectionTitle(group.isComplete ? 'Final cycle' : 'Current cycle'),
          if (rows.isEmpty)
            const EmptyState(
              icon: Icons.payments_outlined,
              title: 'No contributions yet',
              description: 'Contributions will appear when members join.',
            ),
          ...rows.map(
            (row) => Card(
              child: ListTile(
                title: Text(row.memberName),
                subtitle: Text(money(row.amountKobo)),
                trailing: StatusChip(row.status),
              ),
            ),
          ),
          const SectionTitle('Contribution history'),
          if (history.isEmpty)
            const EmptyState(
              icon: Icons.history,
              title: 'No history yet',
              description: 'Past contributions will appear here.',
            ),
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
