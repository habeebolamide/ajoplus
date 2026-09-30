import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'group_dashboard_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final code = TextEditingController();
  SavingsGroup? found;
  bool joining = false;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  void search() {
    if (code.text.trim().isEmpty) {
      showInfo(context, 'Enter an invite code.');
      return;
    }
    final result = context.read<AppProvider>().findInvite(code.text);
    setState(() => found = result);
    if (result == null) {
      showInfo(context, 'No local group matches that invite code.');
    }
  }

  Future<void> join() async {
    if (found == null || joining) return;
    setState(() => joining = true);
    final app = context.read<AppProvider>();
    final user = context.read<AuthProvider>().user!;
    try {
      await app.join(found!, user);
      await app.refreshReminders(user.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GroupDashboardScreen(groupId: found!.id),
        ),
      );
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = context.watch<AuthProvider>().user!;
    final available = app.groups
        .where(
          (group) =>
              !app.isMember(group.id, user.id) &&
              app.groupMembers(group.id).length < group.maxMembers,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Join group')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Find your circle',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Use an invite code from a group on this device.'),
          const SizedBox(height: 20),
          TextField(
            controller: code,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Invite code',
              hintText: 'AJO-XXXXX',
              suffixIcon: IconButton(
                onPressed: search,
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => search(),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: search, child: const Text('Find Group')),
          if (found != null) ...[
            const SectionTitle('Group details'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      found!.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(found!.description),
                    const SizedBox(height: 10),
                    Text(
                      'Organizer: ${found!.creatorId == 'demo' ? 'Habeeblah Adenubi' : 'Local organizer'}',
                    ),
                    Text(
                      'Contribution: ${money(found!.contributionAmountKobo)} · ${found!.frequency}',
                    ),
                    Text(
                      'Members: ${app.groupMembers(found!.id).length}/${found!.maxMembers}',
                    ),
                    Text(
                      'Available slots: ${found!.maxMembers - app.groupMembers(found!.id).length}',
                    ),
                    Text('Starts: ${shortDate(found!.startDate)}'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: joining ? null : join,
                      child: Text(joining ? 'Joining…' : 'Confirm Join'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SectionTitle('Available on this device'),
          ...available.map(
            (group) => Card(
              child: ListTile(
                title: Text(group.name),
                subtitle: Text(
                  '${money(group.contributionAmountKobo)} · ${group.frequency} · ${app.groupMembers(group.id).length}/${group.maxMembers} members',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  code.text = group.inviteCode;
                  setState(() => found = group);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
