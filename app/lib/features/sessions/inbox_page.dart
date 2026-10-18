import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_card.dart';
import '../../core/widgets/w_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/main_bottom_nav.dart';
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

  String _formatRelativeHint(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.isNegative) {
      final past = now.difference(dt);
      if (past.inMinutes < 60) {
        return '${past.inMinutes} min ago';
      } else if (past.inHours < 24) {
        return '${past.inHours} ${past.inHours == 1 ? "hour" : "hours"} ago';
      } else {
        return '${past.inDays} ${past.inDays == 1 ? "day" : "days"} ago';
      }
    } else {
      if (diff.inMinutes < 60) {
        return 'in ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        final hours = diff.inHours;
        final remainingMins = diff.inMinutes % 60;
        if (remainingMins == 0) return 'in $hours hr';
        return 'in ${hours}h ${remainingMins}m';
      } else {
        return 'in ${diff.inDays} ${diff.inDays == 1 ? "day" : "days"}';
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
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
          : state.errorMessage != null && state.incoming.isEmpty && state.outgoing.isEmpty
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
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
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
          return isIncoming ? _buildIncomingCard(req) : _buildOutgoingCard(req);
        },
      ),
    );
  }

  Widget _buildIncomingCard(MentorshipRequest req) {
    final df = DateFormat('MMM d, h:mm a');
    Color chipColor = AppColors.slate;
    if (req.status == 'accepted') chipColor = AppColors.teal;
    if (req.status == 'declined') chipColor = Colors.red;
    if (req.status == 'pending') chipColor = AppColors.amber;

    final student = req.counterpart;
    final studentName = student?.displayName ?? 'Student Mentee';
    final earningsText = req.giverEarningsText ??
        (req.isCrossCollege
            ? 'You earn Rs 175 if completed'
            : 'Free campus session, you earn 1 affinity credit');

    // Priority explanation
    String priorityText = 'Priority: Standard';
    if (req.priority == 3) {
      priorityText = 'Priority: Premium • 3x priority routing';
    } else if (req.priority == 2) {
      priorityText = 'Priority: High • 2x response odds';
    }

    return WCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestDetailPage(request: req, isGiver: true),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: status chip and time received
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Flexible(
                child: Text(
                  'Received ${_formatRelativeHint(req.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Requester identity: Avatar, Name, Headline, Role & Badges
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.teal.withOpacity(0.15),
                child: Text(
                  _getInitials(studentName),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadii.badge,
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Text(
                            'Student',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate),
                          ),
                        ),
                      ],
                    ),
                    if (student?.headline != null && student!.headline!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        student.headline!,
                        style: const TextStyle(fontSize: 12, color: AppColors.slate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Badges
          if (student != null && student.badges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: student.badges.map((b) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.08),
                  borderRadius: AppRadii.badge,
                ),
                child: Text(
                  b,
                  style: const TextStyle(fontSize: 10, color: AppColors.teal, fontWeight: FontWeight.w500),
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 10),

          // Plan Priority with explanation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: req.priority > 1 ? AppColors.amber.withOpacity(0.12) : AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: req.priority > 1 ? AppColors.amber.withOpacity(0.3) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  req.priority > 1 ? Icons.bolt : Icons.schedule,
                  size: 14,
                  color: req.priority > 1 ? const Color(0xFFB45309) : AppColors.slate,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    priorityText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: req.priority > 1 ? const Color(0xFFB45309) : AppColors.slate,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Agenda / Intent Text
          Text(
            req.intentText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),

          // Giver Earnings
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_outlined, size: 16, color: AppColors.teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    earningsText,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Request type and time
          Row(
            children: [
              Icon(
                req.kind == 'instant' ? Icons.flash_on : Icons.calendar_today,
                size: 14,
                color: AppColors.slate,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  req.kind == 'instant'
                      ? 'Instant Request'
                      : 'Booked: ${df.format(req.slotStart?.toLocal() ?? req.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Actions
          if (req.status == 'pending') ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          ] else if (req.status == 'accepted') ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: AppColors.teal),
                    const SizedBox(width: 4),
                    Text(
                      'Session: ${df.format(req.slotStart?.toLocal() ?? req.createdAt)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat_outlined, size: 14),
                  label: const Text('Open chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAction,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RequestDetailPage(request: req, isGiver: true),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutgoingCard(MentorshipRequest req) {
    final giver = req.counterpart;
    final giverName = giver?.displayName ?? 'Mentor';

    return WCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestDetailPage(request: req, isGiver: false),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Giver Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.deepIndigo.withOpacity(0.12),
                child: Text(
                  _getInitials(giverName),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.deepIndigo),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          giverName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadii.badge,
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Text(
                            'Giver',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate),
                          ),
                        ),
                        if (giver?.band != null)
                          _buildBandBadge(giver!.band!),
                      ],
                    ),
                    if (giver?.headline != null && giver!.headline!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        giver.headline!,
                        style: const TextStyle(fontSize: 12, color: AppColors.slate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Badges
          if (giver != null && giver.badges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: giver.badges.map((b) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.08),
                  borderRadius: AppRadii.badge,
                ),
                child: Text(
                  b,
                  style: const TextStyle(fontSize: 10, color: AppColors.teal, fontWeight: FontWeight.w500),
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 10),

          // Topic / Intent
          Text(
            req.intentText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),

          // Status Timeline: Sent -> Accepted -> Completed / Declined / Expired
          _buildStatusTimeline(req.status),

          if (req.status == 'accepted') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_outlined, size: 14),
                label: const Text('Open chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAction,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RequestDetailPage(request: req, isGiver: false),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String status) {
    // Steps: 1. Sent, 2. Accepted, 3. Call Completed
    final isDeclined = status == 'declined';
    final isExpired = status == 'expired';
    final isAccepted = status == 'accepted' || status == 'completed';
    final isCompleted = status == 'completed';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Step 1: Sent
          _buildTimelineStep(
            label: 'Sent',
            isDone: true,
            isActive: false,
          ),
          _buildTimelineLine(isDone: isAccepted || isDeclined || isExpired),

          // Step 2: Accepted / Declined / Expired
          _buildTimelineStep(
            label: isDeclined ? 'Declined' : isExpired ? 'Expired' : 'Accepted',
            isDone: isAccepted,
            isActive: status == 'pending',
            isError: isDeclined || isExpired,
          ),
          _buildTimelineLine(isDone: isCompleted),

          // Step 3: Completed
          _buildTimelineStep(
            label: 'Completed',
            isDone: isCompleted,
            isActive: status == 'accepted',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String label,
    required bool isDone,
    required bool isActive,
    bool isError = false,
  }) {
    Color color = AppColors.slate;
    IconData icon = Icons.circle_outlined;

    if (isError) {
      color = Colors.red;
      icon = Icons.cancel;
    } else if (isDone) {
      color = AppColors.successGreen;
      icon = Icons.check_circle;
    } else if (isActive) {
      color = AppColors.primaryAction;
      icon = Icons.pending_outlined;
    }

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: (isDone || isActive || isError) ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine({required bool isDone}) {
    return Container(
      width: 24,
      height: 2,
      color: isDone ? AppColors.successGreen : const Color(0xFFCBD5E1),
      margin: const EdgeInsets.only(bottom: 12),
    );
  }

  Widget _buildBandBadge(String band) {
    Color bg = AppColors.slate.withOpacity(0.12);
    Color fg = AppColors.slate;
    IconData? icon;

    if (band == 'Top Rated') {
      bg = AppColors.amber.withOpacity(0.18);
      fg = const Color(0xFFB45309);
      icon = Icons.star;
    } else if (band == 'Trusted') {
      bg = AppColors.teal.withOpacity(0.15);
      fg = AppColors.teal;
      icon = Icons.verified;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.badge,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            band,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
          ),
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
