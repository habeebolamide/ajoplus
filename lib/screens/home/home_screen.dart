import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
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
    final ownContributions = app.contributions.where(
      (c) =>
          app.members.any((m) => m.id == c.memberId && m.userId == user.id) &&
          c.status == 'Paid',
    );
    final contributed = ownContributions.fold<int>(
      0,
      (sum, row) => sum + row.amountKobo,
    );
    final upcoming =
        groups.where((g) => g.currentCycle <= g.maxMembers).toList()..sort(
          (a, b) => GroupService.cycleDate(
            a,
            a.currentCycle,
          ).compareTo(GroupService.cycleDate(b, b.currentCycle)),
        );
    final nextContribution = app.nextContribution(user.id, DateTime.now());
    final payoutTurns = <MapEntry<SavingsGroup, int>>[];
    for (final group in upcoming) {
      for (var cycle = group.currentCycle; cycle <= group.maxMembers; cycle++) {
        if (app.recipient(group, cycle)?.userId == user.id) {
          payoutTurns.add(MapEntry(group, cycle));
        }
      }
    }
    payoutTurns.sort(
      (a, b) => GroupService.cycleDate(
        a.key,
        a.value,
      ).compareTo(GroupService.cycleDate(b.key, b.value)),
    );
    final nextPayout = payoutTurns.isEmpty ? null : payoutTurns.first;

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
                        : money(app.expected(nextPayout.key)),
                    detail: nextPayout == null
                        ? null
                        : shortDate(
                            GroupService.cycleDate(
                              nextPayout.key,
                              nextPayout.value,
                            ),
                          ),
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
        if (app.transactions.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            description: 'Your contributions and payouts will appear here.',
          ),
        ...app.transactions.take(3).map((row) => TransactionTile(row)),
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
