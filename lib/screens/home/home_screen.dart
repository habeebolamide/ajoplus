import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/transaction_tile.dart';
import '../groups/create_group_screen.dart';
import '../groups/join_group_screen.dart';
import '../groups/group_dashboard_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final app = context.watch<AppProvider>();
    final groups = app.myGroups(user.id);
    final transactions = app.myTransactions(user.id);
    final ownContributions = app.contributions.where(
      (c) =>
          app.members.any((m) => m.id == c.memberId && m.userId == user.id) &&
          c.status == 'Paid',
    );
    final contributed = ownContributions.fold<int>(
      0,
      (sum, row) => sum + row.amountKobo,
    );
    final nextContribution = app.nextContribution(user.id, DateTime.now());
    final payoutTurns = app.schedule.where((entry) =>
        entry.recipientId == user.id && entry.status != 'completed' &&
        groups.any((group) => group.id == entry.groupId && entry.cycle >= group.currentCycle)).toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    final nextPayout = payoutTurns.firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Good ${_greeting()}, ${user.fullName.split(' ').first}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text('Here is your savings overview.'),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: (width - 8) / 2,
                  child: MetricCard('My Groups', '${groups.length}'),
                ),
                SizedBox(
                  width: (width - 8) / 2,
                  child: MetricCard('Total Contributed', money(contributed)),
                ),
                SizedBox(
                  width: (width - 8) / 2,
                  child: MetricCard(
                    'Next Contribution',
                    nextContribution == null
                        ? '—'
                        : money(nextContribution.group.contributionAmountKobo),
                    detail: nextContribution == null
                        ? null
                        : shortDate(nextContribution.dueDate),
                  ),
                ),
                SizedBox(
                  width: (width - 8) / 2,
                  child: MetricCard(
                    'Next Payout',
                    nextPayout == null
                        ? '—'
                        : money(nextPayout.amountKobo),
                    detail: nextPayout == null
                        ? null
                        : shortDate(nextPayout.scheduledFor),
                  ),
                ),
              ],
            );
          },
        ),
        const SectionTitle('Quick actions'),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateGroupScreen(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create Group'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const JoinGroupScreen(),
                  ),
                ),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Join Group'),
              ),
            ),
          ],
        ),
        const SectionTitle('My groups'),
        if (groups.isEmpty)
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'No groups yet',
            description: "You haven't joined any savings groups yet.",
          ),
        ...groups.map(
          (group) => GroupCard(
            group: group,
            balance: app.balance(group),
            expected: app.expected(group),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => GroupDashboardScreen(groupId: group.id),
              ),
            ),
          ),
        ),
        const SectionTitle('Recent transactions'),
        if (transactions.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            description: 'Your contributions and payouts will appear here.',
          ),
        ...transactions.take(3).map((row) => TransactionTile(row)),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    return hour < 12
        ? 'morning'
        : hour < 17
        ? 'afternoon'
        : 'evening';
  }
}
