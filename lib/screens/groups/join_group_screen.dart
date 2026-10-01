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
  bool requestPending = false;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> search() async {
    if (code.text.trim().isEmpty) {
      showInfo(context, 'Enter an invite code.', kind: FeedbackKind.warning);
      return;
    }
    setState(() {
      searching = true;
      found = null;
      requestPending = false;
    });
    try {
      final result = await context.read<AppProvider>().lookup(code.text);
      if (mounted) {
        setState(() {
          found = result;
          requestPending = result.joinRequestStatus == 'pending';
        });
      }
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
      final result = await app.join(code.text);
      if (result.pendingApproval) {
        if (mounted) {
          setState(() => requestPending = true);
          showInfo(
            context,
            'Your request was sent. The group organizer must approve it before you can join.',
            kind: FeedbackKind.success,
          );
        }
        return;
      }
      await app.refreshReminders(user.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GroupDashboardScreen(groupId: result.groupId),
        ),
      );
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => joining = false);
    }
  }

  Future<void> openApprovedGroup(GroupPreview group) async {
    setState(() => joining = true);
    final app = context.read<AppProvider>();
    final user = context.read<AuthProvider>().user!;
    try {
      await app.refresh();
      await app.refreshReminders(user.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GroupDashboardScreen(groupId: group.id),
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
    final alreadyJoined =
        group?.joinRequestStatus == 'approved' ||
        group?.joinRequestStatus == 'joined';
    final groupIsFull = group != null && group.membersCount >= group.maxMembers;
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
                      group.requiresApproval
                          ? 'Joining requires organizer approval'
                          : 'Anyone with the code can join',
                    ),
                    if (group.joinRequestStatus == 'pending')
                      const Text('Your request is waiting for approval.'),
                    if (group.joinRequestStatus == 'rejected')
                      const Text('Your previous request was declined.'),
                    Text(
                      'Available slots: ${group.maxMembers - group.membersCount}',
                    ),
                    Text('Starts: ${shortDate(group.startDate)}'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: joining
                          ? null
                          : alreadyJoined
                          ? () => openApprovedGroup(group)
                          : requestPending || groupIsFull
                          ? null
                          : join,
                      child: Text(
                        joining
                            ? group.requiresApproval
                                  ? 'Sending request…'
                                  : 'Joining…'
                            : requestPending
                            ? 'Request pending approval'
                            : alreadyJoined
                            ? 'Open Group'
                            : groupIsFull
                            ? 'Group is full'
                            : group.requiresApproval
                            ? 'Request to Join'
                            : 'Confirm Join',
                      ),
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
