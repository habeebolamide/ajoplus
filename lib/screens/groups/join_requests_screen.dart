import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_join_request.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class JoinRequestsScreen extends StatefulWidget {
  final String groupId;

  const JoinRequestsScreen({super.key, required this.groupId});

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  late Future<List<GroupJoinRequest>> requests;
  String? savingRequestId;

  @override
  void initState() {
    super.initState();
    requests = context.read<AppProvider>().joinRequests(widget.groupId);
  }

  Future<void> reload() async {
    setState(() {
      requests = context.read<AppProvider>().joinRequests(widget.groupId);
    });
    await requests;
  }

  Future<void> respond(
    GroupJoinRequest request, {
    required bool approve,
  }) async {
    setState(() => savingRequestId = request.id);
    try {
      final app = context.read<AppProvider>();
      if (approve) {
        await app.approveJoinRequest(widget.groupId, request.id);
      } else {
        await app.rejectJoinRequest(widget.groupId, request.id);
      }
      if (!mounted) return;
      setState(() {
        requests = app.joinRequests(widget.groupId);
        savingRequestId = null;
      });
      showInfo(
        context,
        approve ? 'Member approved.' : 'Request declined.',
        kind: FeedbackKind.success,
      );
    } catch (error) {
      if (mounted) {
        setState(() => savingRequestId = null);
        showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Join requests')),
    body: RefreshIndicator(
      onRefresh: reload,
      child: FutureBuilder<List<GroupJoinRequest>>(
        future: requests,
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (snapshot.hasError)
              EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load requests',
                description: 'Check your connection and try again.',
                action: TextButton(
                  onPressed: reload,
                  child: const Text('Retry'),
                ),
              ),
            if (snapshot.hasData && snapshot.data!.isEmpty)
              const EmptyState(
                icon: Icons.group_add_outlined,
                title: 'No pending requests',
                description:
                    'New requests to join this group will appear here.',
              ),
            if (snapshot.hasData)
              ...snapshot.data!.map(
                (request) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            child: Text(request.name.characters.first),
                          ),
                          title: Text(request.name),
                          subtitle: const Text('Wants to join this group'),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: savingRequestId == null
                                    ? () => respond(request, approve: false)
                                    : null,
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: savingRequestId == null
                                    ? () => respond(request, approve: true)
                                    : null,
                                child: Text(
                                  savingRequestId == request.id
                                      ? 'Saving…'
                                      : 'Approve',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
