import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/formatters.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../models/savings_group.dart';
import '../../models/payout.dart';
import '../../widgets/common.dart';
import '../transactions/transactions_screen.dart';
import 'members_screen.dart';
import '../contributions/contributions_screen.dart';
import 'payout_schedule_screen.dart';
import 'join_requests_screen.dart';

class GroupDashboardScreen extends StatefulWidget {
  final String groupId;
  const GroupDashboardScreen({super.key, required this.groupId});

  @override
  State<GroupDashboardScreen> createState() => _GroupDashboardScreenState();
}

class _GroupDashboardScreenState extends State<GroupDashboardScreen> {
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final group = app.group(widget.groupId);
    final user = context.watch<AuthProvider>().user!;
    final count = app.groupMembers(widget.groupId).length;
    final complete = group.isComplete;
    final recipient = complete ? null : app.recipient(group);
    final expected = app.expected(group);
    final balance = app.balance(group);
    final own = app.ownContribution(group, user.id);
    final finalContributionPaid =
        own?.status == 'Paid' && group.currentCycle == group.totalCycles;
    final nextContributionDate = GroupService.cycleDate(
      group,
      own?.status == 'Paid' && group.currentCycle < group.totalCycles
          ? group.currentCycle + 1
          : group.currentCycle,
    );
    final payoutDates = app.schedule.where(
      (entry) => entry.groupId == group.id && entry.cycle == group.currentCycle,
    );
    final nextPayoutDate = group.isSavings
        ? GroupService.maturityDate(group)
        : payoutDates.isEmpty
        ? GroupService.cycleDate(group, group.currentCycle)
        : payoutDates.first.scheduledFor;
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          if (group.creatorId == user.id && group.requiresApproval && !complete)
            IconButton(
              tooltip: 'Join requests',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => JoinRequestsScreen(groupId: group.id),
                ),
              ),
              icon: const Icon(Icons.how_to_reg_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            group.ajoType.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(group.ajoType.description),
          const SizedBox(height: 12),
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
                        ? group.isSavings
                              ? 'Savings repaid'
                              : 'All cycles complete'
                        : 'Cycle ${group.currentCycle} of ${group.totalCycles}',
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
                    group.isSavings ? 'Total saved' : 'Current balance',
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
                    finalContributionPaid
                        ? 'Contribution'
                        : 'Next contribution',
                    finalContributionPaid
                        ? 'Paid'
                        : shortDate(nextContributionDate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    group.isSavings ? 'Repayment date' : 'Next payout',
                    shortDate(nextPayoutDate),
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
                builder: (_) => MembersScreen(groupId: widget.groupId),
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
                builder: (_) => ContributionsScreen(groupId: widget.groupId),
              ),
            ),
          ),
          _shortcut(
            context,
            Icons.event_note_outlined,
            group.isSavings ? 'Repayment schedule' : 'Payout schedule',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PayoutScheduleScreen(groupId: widget.groupId),
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
                  body: TransactionsTab(groupId: widget.groupId),
                ),
              ),
            ),
          ),
          if (group.creatorId == user.id && !complete) ...[
            const SectionTitle('Organizer'),
            if (group.isSavings && app.hasPendingPayout(group))
              ...app.payouts
                  .where(
                    (payout) =>
                        payout.groupId == group.id &&
                        payout.status == 'Pending',
                  )
                  .map((payout) {
                    final member = app
                        .groupMembers(group.id)
                        .firstWhere((member) => member.id == payout.memberId);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text('${money(payout.amountKobo)} to repay'),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => _settle(app, group, payout: payout),
                              child: const Text('Record repayment'),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
            else if (app.hasPendingPayout(group))
              FilledButton.icon(
                onPressed: saving ? null : () => _settle(app, group),
                icon: const Icon(Icons.account_balance_outlined),
                label: const Text('Record manual settlement'),
              )
            else
              FilledButton.icon(
                onPressed: !saving && app.canComplete(group)
                    ? () => _prepare(app, group)
                    : null,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  group.isSavings
                      ? group.currentCycle < group.totalCycles
                            ? 'Complete savings cycle'
                            : 'Prepare repayments'
                      : 'Prepare payout',
                ),
              ),
            const SizedBox(height: 8),
            Text(
              group.isSavings
                  ? 'Complete each cycle after all members have paid. Savings are held until ${shortDate(GroupService.maturityDate(group))}. Record each repayment only after that member receives the funds.'
                  : 'Available when all ${group.maxMembers} members have joined and paid. Record settlement only after the recipient receives the funds.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _prepare(AppProvider app, SavingsGroup group) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await app.preparePayout(group);
      if (mounted) {
        showInfo(
          context,
          group.isSavings
              ? group.currentCycle < group.totalCycles
                    ? 'Cycle completed. Contributions remain in savings.'
                    : 'Repayments are pending manual settlement.'
              : 'Payout is pending manual settlement.',
          kind: FeedbackKind.warning,
        );
      }
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _settle(
    AppProvider app,
    SavingsGroup group, {
    Payout? payout,
  }) async {
    if (saving) return;
    final controller = TextEditingController();
    final reference = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          payout == null
              ? 'Record manual settlement'
              : 'Repay ${app.groupMembers(group.id).firstWhere((member) => member.id == payout.memberId).name}',
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'External transfer reference',
            helperText: 'Enter the reference from your completed transfer.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Record'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reference == null || reference.length < 4) return;
    if (!mounted) return;
    setState(() => saving = true);
    try {
      await app.settlePayout(group, reference, payoutId: payout?.id);
      if (mounted) {
        showInfo(
          context,
          'Manual settlement recorded.',
          kind: FeedbackKind.success,
        );
      }
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
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
