import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import 'home/home_screen.dart';
import 'groups/groups_screen.dart';
import 'transactions/transactions_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().user!.id;
    unawaited(context.read<AppProvider>().refreshReminders(userId));
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'Groups', 'Transactions', 'Profile'];
    final screens = [
      const HomeTab(),
      const GroupsTab(),
      const TransactionsTab(),
      const ProfileTab(),
    ];
    final userId = context.watch<AuthProvider>().user!.id;
    final unreadCount = context.select<AppProvider, int>(
      (app) => app
          .myNotifications(userId)
          .where((notification) => !notification.isRead)
          .length,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(index == 0 ? 'AjoPlus' : titles[index]),
        actions: index == 0
            ? [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                  icon: unreadCount == 0
                      ? const Icon(Icons.notifications_outlined)
                      : Badge.count(
                          count: unreadCount,
                          child: const Icon(Icons.notifications_outlined),
                        ),
                ),
              ]
            : null,
      ),
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
