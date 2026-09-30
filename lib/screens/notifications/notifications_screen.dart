import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: const NotificationsTab(),
  );
}

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final userId = context.watch<AuthProvider>().user!.id;
    final notifications = app.myNotifications(userId);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (notifications.isEmpty)
          const EmptyState(
            icon: Icons.notifications_none,
            title: "You're all caught up",
            description: 'Reminders and group updates will appear here.',
          ),
        ...notifications.map(
          (row) => Card(
            child: ListTile(
              leading: Icon(
                row.type == 'payout'
                    ? Icons.savings_outlined
                    : Icons.notifications_outlined,
              ),
              title: Text(
                row.title,
                style: TextStyle(
                  fontWeight: row.isRead ? FontWeight.w500 : FontWeight.w800,
                ),
              ),
              subtitle: Text('${row.message}\n${shortDate(row.createdAt)}'),
              isThreeLine: true,
              trailing: row.isRead ? null : const Icon(Icons.circle, size: 9),
              onTap: () => app.readNotification(row),
            ),
          ),
        ),
      ],
    );
  }
}
