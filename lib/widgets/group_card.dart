import 'package:flutter/material.dart';
import '../models/models.dart';

class GroupCard extends StatelessWidget {
  final SavingsGroup group;
  final int balance, expected;
  final VoidCallback onTap;
  const GroupCard({
    super.key,
    required this.group,
    required this.balance,
    required this.expected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(group.name.characters.first)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 14),
            Text('${money(group.contributionAmountKobo)} · ${group.frequency}'),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: expected == 0 ? 0 : (balance / expected).clamp(0, 1),
            ),
            const SizedBox(height: 7),
            Text(
              '${money(balance)} of ${money(expected)} collected',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}
