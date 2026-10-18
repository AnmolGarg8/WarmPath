import 'dart:async';
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
import '../../core/api/websocket_service.dart';
import 'session_models.dart';
import 'sessions_api_service.dart';
import 'session_call_page.dart';

class SessionsPage extends ConsumerStatefulWidget {
  const SessionsPage({super.key});

  @override
  ConsumerState<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends ConsumerState<SessionsPage> {
  List<CallSession> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _initRealtime();
  }

  void _initRealtime() {
    try {
      _wsSubscription = WebSocketService().stream.listen((event) {
        final type = event['type']?.toString();
        if (type == 'new_request' ||
            type == 'request_accepted' ||
            type == 'session_started' ||
            type == 'session_completed') {
          _loadSessions();
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(sessionsApiServiceProvider);
      final list = await api.listMySessions();
      if (mounted) {
        setState(() {
          _sessions = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatRelativeHint(DateTime scheduledAt) {
    final now = DateTime.now();
    final diff = scheduledAt.difference(now);
    if (diff.isNegative) {
      final past = now.difference(scheduledAt);
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

  bool _isSessionJoinable(CallSession s) {
    final now = DateTime.now();
    final opensAt = s.scheduledAt.subtract(const Duration(minutes: 10));
    final endsAt = s.scheduledAt.add(Duration(minutes: s.durationMinutes));
    return now.isAfter(opensAt) && now.isBefore(endsAt) && (s.status == 'scheduled' || s.status == 'in_progress');
  }

  bool _isSessionUpcoming(CallSession s) {
    final now = DateTime.now();
    final opensAt = s.scheduledAt.subtract(const Duration(minutes: 10));
    return now.isBefore(opensAt) && s.status == 'scheduled';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mentorship Sessions'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          Semantics(
            label: 'Mentorship Inbox',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.mark_chat_unread_outlined, color: AppColors.teal),
              tooltip: 'Mentorship Inbox',
              onPressed: () => context.push('/inbox').then((_) => _loadSessions()),
            ),
          ),
          Semantics(
            label: 'Availability & Capacity',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.schedule_outlined, color: AppColors.primaryAction),
              tooltip: 'Availability & Capacity',
              onPressed: () => context.push('/availability').then((_) => _loadSessions()),
            ),
          ),
        ],
      ),
      body: _isLoading && _sessions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _sessions.isEmpty
              ? ErrorState(
                  message: _errorMessage!,
                  onRetry: _loadSessions,
                )
              : _sessions.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadSessions,
                      child: ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          const EmptyState(
                            title: 'No sessions yet',
                            message: 'Accepted mentorship calls will appear here with meeting links.',
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSessions,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) => _buildSessionCard(_sessions[idx]),
                      ),
                    ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
    );
  }

  Widget _buildSessionCard(CallSession s) {
    final df = DateFormat('EEEE, MMM d • h:mm a');
    Color statusColor = AppColors.slate;
    if (s.status == 'in_progress') statusColor = AppColors.teal;
    if (s.status == 'completed') statusColor = AppColors.successGreen;
    if (s.status == 'no_show') statusColor = Colors.red;

    final counterpart = s.counterpart;
    final counterpartName = counterpart?.displayName ?? (counterpart?.role == 'Student' ? 'Student' : 'Mentor');
    final role = counterpart?.role ?? 'Mentor';
    final isStudent = role != 'Student'; // If other is not Student, current user is Student

    return WCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status and Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: AppRadii.badge,
                ),
                child: Text(
                  s.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              Text(
                '${s.durationMinutes} mins',
                style: const TextStyle(color: AppColors.slate, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Counterpart identity row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.teal.withOpacity(0.15),
                child: Text(
                  _getInitials(counterpartName),
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
                          counterpartName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadii.badge,
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate),
                          ),
                        ),
                        if (counterpart?.band != null)
                          _buildBandBadge(counterpart!.band!),
                      ],
                    ),
                    if (counterpart?.headline != null && counterpart!.headline!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        counterpart.headline!,
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

          // Badges row
          if (counterpart != null && counterpart.badges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: counterpart.badges.map((b) => Container(
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

          // Topic / Agenda
          if (s.topic != null && s.topic!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.topic_outlined, size: 14, color: AppColors.slate),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.topic!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Time in device timezone with relative hint
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.slate),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${df.format(s.scheduledAt.toLocal())} (${_formatRelativeHint(s.scheduledAt)})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action buttons
          if (s.status == 'scheduled' || s.status == 'in_progress') ...[
            if (_isSessionJoinable(s))
              WButton(
                label: 'Join Video Call',
                backgroundColor: AppColors.teal,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SessionCallPage(session: s),
                    ),
                  ).then((_) => _loadSessions());
                },
              )
            else if (_isSessionUpcoming(s))
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.lock_clock_outlined, size: 16, color: AppColors.slate),
                  label: const Text('Opens 10 minutes before the start', style: TextStyle(color: AppColors.slate, fontSize: 13)),
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
          ] else if (s.status == 'completed') ...[
            if (isStudent) ...[
              if (s.studentRatingStars != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: AppColors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'You rated ${s.studentRatingStars} stars',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                    ],
                  ),
                )
              else if (DateTime.now().difference(s.scheduledAt).inDays <= 14)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.star, size: 16, color: AppColors.white),
                    label: const Text('Rate session', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      context.push('/ratings/rate', extra: {
                        'session_id': s.id,
                        'is_giver': false,
                      }).then((_) => _loadSessions());
                    },
                  ),
                )
              else
                const Text(
                  'Rating window closed (14 days)',
                  style: TextStyle(color: AppColors.slate, fontSize: 12),
                ),
            ] else ...[
              if (!s.giverRatedQuality)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 16, color: AppColors.primaryAction),
                    label: const Text('Rate request quality', style: TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryAction),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      context.push('/ratings/rate', extra: {
                        'session_id': s.id,
                        'is_giver': true,
                      }).then((_) => _loadSessions());
                    },
                  ),
                )
              else
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: AppColors.successGreen, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Request quality rated',
                      style: TextStyle(color: AppColors.successGreen, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ],
        ],
      ),
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
}
