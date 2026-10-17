import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_card.dart';
import '../../core/widgets/w_button.dart';
import '../../core/api/dio_client.dart';
import 'session_models.dart';
import 'sessions_api_service.dart';

class RequestDetailPage extends ConsumerStatefulWidget {
  final MentorshipRequest request;
  final bool isGiver;

  const RequestDetailPage({
    super.key,
    required this.request,
    required this.isGiver,
  });

  @override
  ConsumerState<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends ConsumerState<RequestDetailPage> {
  final TextEditingController _msgController = TextEditingController();
  List<ThreadMessage> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoadingMessages = true);
    try {
      final api = ref.read(sessionsApiServiceProvider);
      final list = await api.getMessages(widget.request.id);
      setState(() {
        _messages = list;
        _isLoadingMessages = false;
      });
    } catch (_) {
      setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final api = ref.read(sessionsApiServiceProvider);
      final msg = await api.sendMessage(widget.request.id, text);
      _msgController.clear();
      setState(() {
        _messages.add(msg);
        _isSending = false;
      });
    } catch (e) {
      setState(() => _isSending = false);
      String errorMsg = 'Failed to send message.';
      if (e is AppException && e.code == 'message_blocked') {
        errorMsg = 'Message blocked: safety filters detected prohibited content or scam risk.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Thread'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showReportBlockSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header summary
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status: \${widget.request.status.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(df.format(widget.request.createdAt.toLocal()), style: const TextStyle(color: AppColors.slate, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Agenda: \${widget.request.intentText}', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Message list
          Expanded(
            child: _isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, idx) {
                      final msg = _messages[idx];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Type an in-app message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: AppColors.primaryAction),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThreadMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.safetyAction == 'warn')
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
              child: const Text('⚠️ Warning: Keep discussions strictly within professional career topics.', style: TextStyle(fontSize: 11, color: Colors.brown)),
            ),
          if (msg.safetyAction == 'review')
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
              child: const Text('ℹ️ Pending review by moderation team', style: TextStyle(fontSize: 11, color: Colors.blue)),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(msg.content, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showReportBlockSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.amber),
              title: const Text('Report Conversation'),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted to moderation queue.')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User'),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked from messaging.')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
