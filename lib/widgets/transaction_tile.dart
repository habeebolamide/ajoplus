import 'package:flutter/material.dart';
import '../models/models.dart';
import 'status_chip.dart';

class TransactionTile extends StatelessWidget {
  final AppTransaction row;
  const TransactionTile(this.row, {super.key});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        child: Icon(
          row.type == 'Payout' ? Icons.arrow_downward : Icons.arrow_upward,
        ),
      ),
      title: Text(row.type),
      subtitle: Text(
        '${row.memberName} · ${row.groupName}\n${shortDate(row.createdAt)}',
      ),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            money(row.amountKobo),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          StatusChip(row.status),
        ],
      ),
    ),
  );
}
