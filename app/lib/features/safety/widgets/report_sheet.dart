import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/app_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_button.dart';
import '../safety_providers.dart';
import 'block_dialog.dart';

class ReportSheet extends ConsumerStatefulWidget {
  final String? targetUserId;
  final String? messageId;
  final String? requestId;
  final String? targetName;

  const ReportSheet({
    super.key,
    this.targetUserId,
    this.messageId,
    this.requestId,
    this.targetName,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? targetUserId,
    String? messageId,
    String? requestId,
    String? targetName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReportSheet(
        targetUserId: targetUserId,
        messageId: messageId,
        requestId: requestId,
        targetName: targetName,
      ),
    );
  }

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<Map<String, String>> _reasons = [
    {
      'id': 'scam_fraud',
      'label': 'Asking for money / fees / deposit',
      'desc': 'User asked for registration fee, advance payment, or security deposit.',
    },
    {
      'id': 'off_platform',
      'label': 'Pushing to WhatsApp / Telegram',
      'desc': 'User attempted to move discussion outside WarmPath to avoid safety rules.',
    },
    {
      'id': 'harassment',
      'label': 'Harassment or Inappropriate Conduct',
      'desc': 'Unprofessional communication, offensive language, or boundary violation.',
    },
    {
      'id': 'fake_profile',
      'label': 'Fake Profile / Misrepresented Identity',
      'desc': 'User is impersonating someone else or falsified credentials.',
    },
    {
      'id': 'other',
      'label': 'Other safety concern',
      'desc': 'Any other violation of WarmPath trust and safety guidelines.',
    },
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      setState(() => _errorMessage = 'Please select a reason for this report.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(safetyRepositoryProvider);
      await repo.createReport(
        targetUserId: widget.targetUserId,
        messageId: widget.messageId,
        requestId: widget.requestId,
        reason: _selectedReason!,
        details: _detailsController.text.trim().isNotEmpty
            ? _detailsController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report submitted. Our moderation team has been notified.'),
            action: widget.targetUserId != null
                ? SnackBarAction(
                    label: 'Block User',
                    textColor: AppColors.primaryAction,
                    onPressed: () {
                      showBlockDialog(
                        context,
                        targetUserId: widget.targetUserId!,
                        targetName: widget.targetName,
                      );
                    },
                  )
                : null,
          ),
        );
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Failed to submit report. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.report_problem_outlined, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    widget.targetName != null
                        ? 'Report ${widget.targetName}'
                        : 'Submit Community Report',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Reports are strictly confidential. Verified moderators review every report to keep WarmPath safe.',
                style: TextStyle(fontSize: 13, color: AppColors.slate),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Reason *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              ..._reasons.map((r) {
                final isSelected = _selectedReason == r['id'];
                return InkWell(
                  onTap: () => setState(() => _selectedReason = r['id']),
                  borderRadius: AppRadii.button,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryAction.withOpacity(0.08)
                          : AppColors.surface,
                      borderRadius: AppRadii.button,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryAction
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18,
                          color: isSelected ? AppColors.primaryAction : AppColors.slate,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppColors.primaryAction : AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r['desc']!,
                                style: const TextStyle(fontSize: 11, color: AppColors.slate),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              const Text(
                'Additional Details (Optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe what happened or provide context...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.button,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: WButton(
                  label: 'Submit Confidential Report',
                  isLoading: _isSubmitting,
                  onPressed: _submitReport,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> showReportSheet(
  BuildContext context, {
  String? targetUserId,
  String? messageId,
  String? requestId,
  String? targetName,
}) {
  return ReportSheet.show(
    context,
    targetUserId: targetUserId,
    messageId: messageId,
    requestId: requestId,
    targetName: targetName,
  );
}
