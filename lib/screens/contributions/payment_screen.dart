import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../utils/formatters.dart';
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

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  bool busy = false;
  bool checkoutOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && checkoutOpened && !busy) {
      checkPayment();
    }
  }

  Future<void> startCheckout() async {
    final app = context.read<AppProvider>();
    final group = app.group(widget.groupId);
    final row = app.contributions.firstWhere(
      (item) => item.id == widget.contributionId,
    );
    setState(() => busy = true);
    try {
      final url = await app.checkout(group, row);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw StateError('Could not open Paystack checkout. Please retry.');
      }
      if (mounted) setState(() => checkoutOpened = true);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> checkPayment() async {
    final app = context.read<AppProvider>();
    final group = app.group(widget.groupId);
    final row = app.contributions.firstWhere(
      (item) => item.id == widget.contributionId,
    );
    setState(() => busy = true);
    try {
      final verified = await app.verifyPayment(group, row);
      if (!mounted) return;
      if (verified.status == 'Paid') {
        showInfo(
          context,
          'Payment verified. Reference: ${verified.paymentReference}',
          kind: FeedbackKind.success,
        );
        Navigator.pop(context);
      } else if (verified.status == 'Failed') {
        setState(() => checkoutOpened = false);
        showInfo(
          context,
          'Payment failed. You can retry checkout.',
          kind: FeedbackKind.error,
        );
      } else {
        showInfo(
          context,
          'Payment is still pending. Check again after completing checkout.',
          kind: FeedbackKind.warning,
        );
      }
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
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
      appBar: AppBar(title: const Text('Contribution payment')),
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
            'Pay with Paystack',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'You will complete payment in Paystack checkout. We will verify it with Paystack before recording your contribution.',
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
            onPressed: busy ? null : startCheckout,
            child: Text(
              busy
                  ? 'Please wait…'
                  : checkoutOpened
                  ? 'Open checkout again'
                  : 'Continue to Paystack',
            ),
          ),
          if (checkoutOpened)
            TextButton(
              onPressed: busy ? null : checkPayment,
              child: const Text('Check payment status'),
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
