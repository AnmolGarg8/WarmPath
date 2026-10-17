import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_card.dart';
import '../../core/widgets/w_button.dart';
import '../../core/widgets/empty_state.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(sessionsApiServiceProvider);
      final list = await api.listMySessions();
      setState(() {
        _sessions = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mentorship Sessions'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
    );
  }

  Widget _buildSessionCard(CallSession s) {
    final df = DateFormat('EEEE, MMM d • h:mm a');
    Color statusColor = AppColors.slate;
    if (s.status == 'in_progress') statusColor = AppColors.teal;
    if (s.status == 'completed') statusColor = AppColors.successGreen;
    if (s.status == 'no_show') statusColor = Colors.red;

    return WCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                '\${s.durationMinutes} mins',
                style: const TextStyle(color: AppColors.slate, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            df.format(s.scheduledAt.toLocal()),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 14),
          if (s.status == 'scheduled' || s.status == 'in_progress')
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
          else if (s.status == 'completed')
            OutlinedButton.icon(
              icon: const Icon(Icons.star_outline),
              label: const Text('Leave Feedback / Review'),
              onPressed: () {
                // Navigate to rating
              },
            ),
        ],
      ),
    );
  }
}
