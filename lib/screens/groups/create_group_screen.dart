import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
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
  String frequency = 'Monthly';
  DateTime? startDate;
  bool saving = false;

  @override
  void dispose() {
    for (final controller in [name, description, amount, members]) {
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
        maxMembers: int.parse(members.text),
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
            const Text('Invite members with the code created for your group.'),
            const SizedBox(height: 24),
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
            const SizedBox(height: 14),
            TextFormField(
              controller: members,
              decoration: const InputDecoration(labelText: 'Number of members'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (int.tryParse(value ?? '') ?? 0) < 2 ||
                      (int.tryParse(value ?? '') ?? 0) > 100
                  ? 'Choose 2 to 100 members'
                  : null,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: chooseDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                startDate == null ? 'Choose start date' : shortDate(startDate!),
              ),
            ),
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
