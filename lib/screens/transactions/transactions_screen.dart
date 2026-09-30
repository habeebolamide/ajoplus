import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/transaction_tile.dart';

class TransactionsTab extends StatefulWidget {
  final String? groupId;
  const TransactionsTab({super.key, this.groupId});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final userId = context.watch<AuthProvider>().user!.id;
    final rows = app
        .myTransactions(userId)
        .where(
          (row) =>
              (widget.groupId == null || row.groupId == widget.groupId) &&
              (filter == 'All' ||
                  row.type ==
                      (filter == 'Contributions' ? 'Contribution' : 'Payout')),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: ['All', 'Contributions', 'Payouts']
              .map(
                (item) => ChoiceChip(
                  label: Text(item),
                  selected: filter == item,
                  onSelected: (_) => setState(() => filter = item),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            description: 'Completed payments and payouts will appear here.',
          ),
        ...rows.map((row) => TransactionTile(row)),
      ],
    );
  }
}
