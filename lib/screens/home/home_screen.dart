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
    final payoutTurns =
        app.schedule
            .where(
              (entry) =>
                  entry.recipientId == user.id &&
                  entry.status != 'completed' &&
                  groups.any(
                    (group) =>
                        group.id == entry.groupId &&
                        entry.cycle >= group.currentCycle,
                  ),
            )
            .toList()
          ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    final nextPayout = payoutTurns.firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          'Good ${_greeting()},\n${user.fullName.split(' ').first}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Your savings, moving forward.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          color: Theme.of(context).colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL CONTRIBUTED',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: .78),
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        money(contributed),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${groups.length} active ${groups.length == 1 ? 'group' : 'groups'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: .82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.savings_outlined,
                  size: 36,
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: .85),
                ),
              ],
            ),
          ),
        ),
        if (groups.isEmpty) ...[
          const SectionTitle('My groups'),
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'No groups yet',
            description:
                "Create a savings group or join one with an invite code.",
          ),
        ],
        const SectionTitle('Your overview'),
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
                    nextPayout == null ? '—' : money(nextPayout.amountKobo),
                    detail: nextPayout == null
                        ? null
                        : shortDate(nextPayout.scheduledFor),
                  ),
                ),
              ],
            );
          },
        ),
        const SectionTitle('Get started'),
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
        if (groups.isNotEmpty) const SectionTitle('My groups'),
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
