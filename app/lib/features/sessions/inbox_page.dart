import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_card.dart';
import '../../core/widgets/w_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import 'session_models.dart';
import 'sessions_controller.dart';
import 'request_detail_page.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentorship Inbox'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryAction,
          unselectedLabelColor: AppColors.slate,
          indicatorColor: AppColors.primaryAction,
          tabs: const [
            Tab(text: 'Incoming (Giver)'),
            Tab(text: 'Outgoing (Student)'),
          ],
        ),
      ),
      body: state.isLoading && state.incoming.isEmpty && state.outgoing.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.incoming.isEmpty
              ? ErrorState(
                  message: state.errorMessage!,
                  onRetry: () => ref.read(requestsProvider.notifier).loadRequests(),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestList(state.incoming, isIncoming: true),
                    _buildRequestList(state.outgoing, isIncoming: false),
                  ],
                ),
    );
  }

  Widget _buildRequestList(List<MentorshipRequest> requests, {required bool isIncoming}) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(requestsProvider.notifier).loadRequests(),
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            EmptyState(
              title: isIncoming ? 'No incoming requests' : 'No outgoing requests',
              message: isIncoming
                  ? 'When students reach out for mentorship, requests will appear here.'
                  : 'You have not submitted any mentorship requests yet.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(requestsProvider.notifier).loadRequests(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final req = requests[idx];
          return _buildRequestCard(req, isIncoming: isIncoming);
        },
      ),
    );
  }

  Widget _buildRequestCard(MentorshipRequest req, {required bool isIncoming}) {
    final df = DateFormat('MMM d, h:mm a');
    Color chipColor = AppColors.slate;
    if (req.status == 'accepted') chipColor = AppColors.teal;
    if (req.status == 'declined') chipColor = Colors.red;
    if (req.status == 'pending') chipColor = AppColors.amber;

    return WCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestDetailPage(request: req, isGiver: isIncoming),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: chipColor.withOpacity(0.12),
                      borderRadius: AppRadii.badge,
                    ),
                    child: Text(
                      req.status.toUpperCase(),
                      style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  if (req.priority > 1) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withOpacity(0.15),
                        borderRadius: AppRadii.badge,
                      ),
                      child: Text(
                        req.priority == 3 ? 'PREMIUM' : 'HIGH',
                        style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                df.format(req.createdAt.toLocal()),
                style: const TextStyle(fontSize: 12, color: AppColors.slate),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            req.intentText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                req.kind == 'instant' ? Icons.flash_on : Icons.calendar_today,
                size: 14,
                color: AppColors.slate,
              ),
              const SizedBox(width: 4),
              Text(
                req.kind == 'instant' ? 'Instant Request' : 'Booked: \${df.format(req.slotStart?.toLocal() ?? req.createdAt)}',
                style: const TextStyle(fontSize: 12, color: AppColors.slate),
              ),
            ],
          ),
          if (isIncoming && req.status == 'pending') ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _showDeclineDialog(req.id),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: () async {
                      final session = await ref.read(requestsProvider.notifier).acceptRequest(req.id);
                      if (session != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request accepted! Session scheduled.')),
                        );
                      }
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showDeclineDialog(String requestId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'e.g. Schedule full this week',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(requestsProvider.notifier).declineRequest(requestId, reasonController.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }
}
