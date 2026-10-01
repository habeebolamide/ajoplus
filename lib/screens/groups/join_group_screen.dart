import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_preview.dart';
import '../../utils/formatters.dart';
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
  GroupPreview? found;
  bool joining = false;
  bool searching = false;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> search() async {
    if (code.text.trim().isEmpty) {
      showInfo(context, 'Enter an invite code.');
      return;
    }
    setState(() {
      searching = true;
      found = null;
    });
    try {
      final result = await context.read<AppProvider>().lookup(code.text);
      if (mounted) setState(() => found = result);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> join() async {
    final group = found;
    if (group == null || joining) return;
    setState(() => joining = true);
    final app = context.read<AppProvider>();
    final user = context.read<AuthProvider>().user!;
    try {
      final joined = await app.join(code.text);
      await app.refreshReminders(user.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GroupDashboardScreen(groupId: joined.id),
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
    final group = found;
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
          const Text('Enter the invite code shared by a group organizer.'),
          const SizedBox(height: 20),
          TextField(
            controller: code,
            onChanged: (_) => setState(() => found = null),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Invite code',
              suffixIcon: IconButton(
                onPressed: searching ? null : search,
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => search(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: searching ? null : search,
            child: Text(searching ? 'Finding…' : 'Find Group'),
          ),
          if (group != null) ...[
            const SectionTitle('Group details'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(group.description),
                    const SizedBox(height: 10),
                    Text(
                      'Contribution: ${money(group.amountKobo)} · ${group.frequency}',
                    ),
                    Text('Members: ${group.membersCount}/${group.maxMembers}'),
                    Text(
                      'Available slots: ${group.maxMembers - group.membersCount}',
                    ),
                    Text('Starts: ${shortDate(group.startDate)}'),
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
        ],
      ),
    );
  }
}
