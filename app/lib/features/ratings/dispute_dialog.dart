import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_button.dart';
import 'ratings_api_service.dart';

class DisputeDialog extends StatefulWidget {
  final String sessionId;
  final RatingsApiService api;

  const DisputeDialog({
    super.key,
    required this.sessionId,
    required this.api,
  });

  @override
  State<DisputeDialog> createState() => _DisputeDialogState();
}

class _DisputeDialogState extends State<DisputeDialog> {
  String _reason = 'no_show';
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final details = _detailsController.text.trim();
    if (details.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue in at least 10 characters.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.api.openDispute(
        sessionId: widget.sessionId,
        reason: _reason,
        details: details,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dispute submission failed: \$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open Session Dispute'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Disputes must be opened within 48 hours of session completion. Payouts will be held pending moderator review.',
              style: TextStyle(fontSize: 12, color: AppColors.slate),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _reason,
              decoration: const InputDecoration(labelText: 'Dispute Reason'),
              items: const [
                DropdownMenuItem(value: 'no_show', child: Text('No-Show (Absent)')),
                DropdownMenuItem(value: 'low_effort', child: Text('Low Effort / Inadequate Session')),
                DropdownMenuItem(value: 'abusive', child: Text('Unprofessional / Abusive')),
                DropdownMenuItem(value: 'other', child: Text('Other Issue')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _reason = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Details of the incident',
                hintText: 'Describe what happened during the session...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Dispute'),
        ),
      ],
    );
  }
}
