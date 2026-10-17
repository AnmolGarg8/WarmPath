/// Dialog to donate earned or available credits to the scholarship pool.
/// Owner: M4
library;

import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_button.dart';

class DonateDialog extends StatefulWidget {
  final int maxCredits;
  final Future<void> Function(int credits) onDonate;

  const DonateDialog({
    super.key,
    required this.maxCredits,
    required this.onDonate,
  });

  @override
  State<DonateDialog> createState() => _DonateDialogState();
}

class _DonateDialogState extends State<DonateDialog> {
  int _selectedCredits = 1;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      title: const Row(
        children: [
          Icon(Icons.volunteer_activism, color: AppColors.primaryAction),
          SizedBox(width: 8),
          Text(
            'Donate to Scholarship Pool',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your donated credits directly fund sponsored cross-college mentorship seats for students in need.',
            style: TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          Text(
            'Credits available to donate: ${widget.maxCredits}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.remove),
                onPressed: _selectedCredits > 1
                    ? () => setState(() => _selectedCredits--)
                    : null,
              ),
              const SizedBox(width: 20),
              Text(
                '$_selectedCredits',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryAction,
                ),
              ),
              const SizedBox(width: 20),
              IconButton.outlined(
                icon: const Icon(Icons.add),
                onPressed: _selectedCredits < widget.maxCredits
                    ? () => setState(() => _selectedCredits++)
                    : null,
              ),
            ],
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
          child: const Text('Cancel', style: TextStyle(color: AppColors.slate)),
        ),
        WButton(
          label: 'Donate $_selectedCredits ${_selectedCredits == 1 ? 'Credit' : 'Credits'}',
          isLoading: _isLoading,
          onPressed: () async {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            try {
              await widget.onDonate(_selectedCredits);
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
