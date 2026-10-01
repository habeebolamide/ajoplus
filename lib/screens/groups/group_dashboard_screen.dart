import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/formatters.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../models/savings_group.dart';
import '../../widgets/common.dart';
import '../transactions/transactions_screen.dart';
import 'members_screen.dart';
import '../contributions/contributions_screen.dart';
import 'payout_schedule_screen.dart';

class GroupDashboardScreen extends StatelessWidget {
  final String groupId;
  const GroupDashboardScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final group = app.group(groupId);
    final user = context.watch<AuthProvider>().user!;
    final count = app.groupMembers(groupId).length;
    final complete = group.currentCycle > group.maxMembers;
    final recipient = complete ? null : app.recipient(group);
    final expected = app.expected(group);
    final balance = app.balance(group);
    final nextContributionDate = GroupService.cycleDate(group,
        app.ownContribution(group, user.id)?.status == 'Paid' && group.currentCycle < group.maxMembers
            ? group.currentCycle + 1 : group.currentCycle);
    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(group.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            'Invite code: ${group.inviteCode}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complete
                        ? 'All cycles complete'
                        : 'Cycle ${group.currentCycle} of ${group.maxMembers}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${money(group.contributionAmountKobo)} · ${group.frequency}',
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Current balance',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${money(balance)} / ${money(expected)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: GroupService.progress(balance, expected),
                  ),
                  const SizedBox(height: 10),
                  Text('$count of ${group.maxMembers} members joined'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (!complete)
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    'Next contribution',
                    shortDate(nextContributionDate),
                  ),
                ),
                Expanded(
                  child: MetricCard(
                    'Next payout',
                    shortDate(
                      GroupService.cycleDate(group, group.currentCycle),
                    ),
                  ),
                ),
              ],
            ),
          if (recipient != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.celebration_outlined),
                title: const Text('Current payout recipient'),
                subtitle: Text(recipient.name),
                trailing: Text(money(expected)),
              ),
            ),
          const SectionTitle('Group activity'),
          _shortcut(
            context,
            Icons.people_outline,
            'Members',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => MembersScreen(groupId: groupId),
              ),
            ),
          ),
          _shortcut(
            context,
            Icons.payments_outlined,
            'Contributions',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ContributionsScreen(groupId: groupId),
              ),
            ),
          ),
          _shortcut(
            context,
            Icons.event_note_outlined,
            'Payout schedule',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PayoutScheduleScreen(groupId: groupId),
              ),
            ),
          ),
          _shortcut(
            context,
            Icons.receipt_long_outlined,
            'Transactions',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Group transactions')),
                  body: TransactionsTab(groupId: groupId),
                ),
              ),
            ),
          ),
          if (group.creatorId == user.id && !complete) ...[
            const SectionTitle('Organizer'),
            if (app.hasPendingPayout(group)) FilledButton.icon(
              onPressed: () => _settle(context, app, group),
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('Record manual settlement'),
            ) else FilledButton.icon(
              onPressed: app.canComplete(group)
                  ? () async {
                      try {
                        await app.preparePayout(group);
                        if (context.mounted) {
                          showInfo(
                            context,
                            'Payout is pending manual settlement.',
                          );
                        }
                      } catch (error) {
                        if (context.mounted) showError(context, error);
                      }
                    }
                  : null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Prepare payout'),
            ),
            const SizedBox(height: 8),
            Text(
              'Available when all ${group.maxMembers} members have joined and paid. Record settlement only after the recipient receives the funds.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _settle(BuildContext context, AppProvider app, SavingsGroup group) async {
    final controller = TextEditingController();
    final reference = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Record manual settlement'),
      content: TextField(controller: controller, decoration: const InputDecoration(
        labelText: 'External transfer reference',
        helperText: 'Enter the reference from your completed transfer.',
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Record')),
      ],
    ));
    controller.dispose();
    if (reference == null || reference.length < 4) return;
    try {
      await app.settlePayout(group, reference);
      if (context.mounted) showInfo(context, 'Manual settlement recorded.');
    } catch (error) {
      if (context.mounted) showError(context, error);
    }
  }

  Widget _shortcut(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
