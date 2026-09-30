import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';
import 'group_dashboard_screen.dart';

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = context.watch<AuthProvider>().user!;
    final groups = app.myGroups(user.id);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateGroupScreen(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const JoinGroupScreen(),
                  ),
                ),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Join'),
              ),
            ),
          ],
        ),
        const SectionTitle('My savings groups'),
        if (groups.isEmpty)
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'No groups yet',
            description: "You haven't joined any savings groups yet.",
          ),
        ...groups.map(
          (group) => GroupCard(
            group: group,
            balance: app.balance(group),
            expected: app.expected(group),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => GroupDashboardScreen(groupId: group.id),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
