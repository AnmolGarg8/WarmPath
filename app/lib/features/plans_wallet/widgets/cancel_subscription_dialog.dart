/// Confirmation dialog for cancelling subscription at period end.
/// Owner: M4
library;

import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_button.dart';

class CancelSubscriptionDialog extends StatefulWidget {
  final String planName;
  final String renewalDateText;
  final Future<void> Function() onConfirm;

  const CancelSubscriptionDialog({
    super.key,
    required this.planName,
    required this.renewalDateText,
    required this.onConfirm,
  });

  @override
  State<CancelSubscriptionDialog> createState() => _CancelSubscriptionDialogState();
}

class _CancelSubscriptionDialogState extends State<CancelSubscriptionDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      title: const Text(
        'Cancel Subscription?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your ${widget.planName} subscription will remain active until the end of your current billing period (${widget.renewalDateText}).',
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          const Text(
            'You will keep your remaining credits and access to mentorship bookings until then. You will not be charged again.',
            style: TextStyle(fontSize: 13, color: AppColors.slate),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Keep Plan', style: TextStyle(color: AppColors.slate)),
        ),
        WButton(
          label: 'Confirm Cancellation',
          isLoading: _isLoading,
          backgroundColor: AppColors.slate,
          onPressed: () async {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            try {
              await widget.onConfirm();
              if (mounted) Navigator.of(context).pop(true);
            } catch (e) {
              if (mounted) {
                setState(() {
                  _errorMessage = e.toString();
                  _isLoading = false;
                });
              }
            }
          },
        ),
      ],
    );
  }
}
