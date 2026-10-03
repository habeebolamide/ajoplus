import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../../models/savings_group.dart';
import '../../services/group_service.dart';
import 'group_dashboard_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final description = TextEditingController();
  final amount = TextEditingController();
  final members = TextEditingController();
  final duration = TextEditingController();
  AjoType ajoType = AjoType.rotating;
  String frequency = 'Monthly';

  String get periodUnit => switch (frequency) {
    'Daily' => 'days',
    'Weekly' => 'weeks',
    'Biweekly' => 'fortnights',
    _ => 'months',
  };

  DateTime? get repaymentDate {
    final date = startDate;
    final cycles = int.tryParse(duration.text);
    if (date == null || cycles == null || cycles < 1 || cycles > 365) {
      return null;
    }
    return GroupService.dateForCycle(date, frequency, cycles + 1);
  }

  bool requiresApproval = true;
  DateTime? startDate;
  bool saving = false;

  @override
  void dispose() {
    for (final controller in [name, description, amount, members, duration]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> chooseDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null && mounted) setState(() => startDate = picked);
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    if (startDate == null) {
      showInfo(context, 'Choose a start date.', kind: FeedbackKind.warning);
      return;
    }
    setState(() => saving = true);
    final app = context.read<AppProvider>();
    final user = context.read<AuthProvider>().user!;
    try {
      final group = await app.createGroup(
        user: user,
        name: name.text,
        description: description.text,
        amountKobo: parseNairaToKobo(amount.text)!,
        frequency: frequency,
        ajoType: ajoType,
        savingsCycles: ajoType == AjoType.savings
            ? int.parse(duration.text)
            : null,
        maxMembers: int.parse(members.text),
        requiresApproval: requiresApproval,
        startDate: startDate!,
      );
      await app.refreshReminders(user.id);
      if (!mounted) return;
      showInfo(
        context,
        'Group created. Share invite code ${group.inviteCode}.',
        kind: FeedbackKind.success,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GroupDashboardScreen(groupId: group.id),
        ),
      );
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create group')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start a savings circle',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how your group will save and receive its money.',
            ),
            const SizedBox(height: 20),
            Text('Ajo type', style: Theme.of(context).textTheme.titleMedium),
            RadioGroup<AjoType>(
              groupValue: ajoType,
              onChanged: (value) {
                if (value != null) setState(() => ajoType = value);
              },
              child: Column(
                children: AjoType.values
                    .map(
                      (type) => RadioListTile<AjoType>(
                        contentPadding: EdgeInsets.zero,
                        value: type,
                        enabled: !saving,
                        title: Text(type.label),
                        subtitle: Text(type.description),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Group name'),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? 'Enter a group name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Enter a description'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: amount,
              decoration: const InputDecoration(
                labelText: 'Contribution amount',
                prefixText: '₦',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) => parseNairaToKobo(value ?? '') == null
                  ? 'Enter a valid amount in naira (up to 2 decimal places)'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: ['Daily', 'Weekly', 'Biweekly', 'Monthly']
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => frequency = value ?? frequency),
            ),
            if (ajoType == AjoType.savings) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: duration,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Savings duration ($periodUnit)',
                  helperText:
                      'Choose 1 to 365 $periodUnit. Everyone is repaid at the end.',
                  helperMaxLines: 2,
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final cycles = int.tryParse(value ?? '');
                  return cycles == null || cycles < 1 || cycles > 365
                      ? 'Enter a duration from 1 to 365 $periodUnit'
                      : null;
                },
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: members,
              decoration: const InputDecoration(labelText: 'Number of members'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (int.tryParse(value ?? '') ?? 0) < 2 ||
                      (int.tryParse(value ?? '') ?? 0) > 200
                  ? 'Choose 2 to 200 members'
                  : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: requiresApproval,
              onChanged: (value) => setState(() => requiresApproval = value),
              title: const Text('Approve members before they join'),
              subtitle: Text(
                requiresApproval
                    ? 'People with the invite code must wait for your approval.'
                    : 'Anyone with the invite code can join until the group is full.',
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: chooseDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                startDate == null ? 'Choose start date' : shortDate(startDate!),
              ),
            ),
            if (ajoType == AjoType.savings && repaymentDate != null) ...[
              const SizedBox(height: 12),
              Text(
                'Repayment date: ${shortDate(repaymentDate!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Each member receives their accumulated contributions. No rotating payouts.',
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : submit,
              child: Text(saving ? 'Creating…' : 'Create Group'),
            ),
          ],
        ),
      ),
    ),
  );
}
