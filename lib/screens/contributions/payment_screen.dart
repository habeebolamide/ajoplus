import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class PaymentScreen extends StatefulWidget {
  final String groupId, contributionId;
  const PaymentScreen({
    super.key,
    required this.groupId,
    required this.contributionId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Future<void> process(bool succeed) async {
    final app = context.read<AppProvider>();
    final user = context.read<AuthProvider>().user!;
    final group = app.group(widget.groupId);
    final rows = app.contributions.where(
      (row) => row.id == widget.contributionId,
    );
    if (rows.isEmpty) return;
    try {
      final reference = await app.pay(group, rows.first, succeed: succeed);
      unawaited(app.refreshReminders(user.id));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment successful'),
          content: Text('Contribution recorded.\nReference: $reference'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final group = app.group(widget.groupId);
    final row = app.contributions.firstWhere(
      (item) => item.id == widget.contributionId,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.lock_outline,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            'Mock payment',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'No real money is transferred.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _detail('Group', group.name),
                  _detail('Member', row.memberName),
                  _detail('Cycle', '${row.cycle}'),
                  _detail('Amount', money(row.amountKobo)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: app.busy ? null : () => process(true),
            child: Text(app.busy ? 'Processing…' : 'Pay Contribution'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: app.busy ? null : () => process(false),
            child: const Text('Simulate failed payment'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
