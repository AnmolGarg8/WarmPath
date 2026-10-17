/// Dialog for givers to request cash-out in test mode.
/// Owner: M4
library;

import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_button.dart';

class CashoutDialog extends StatefulWidget {
  final int availableInr;
  final Future<void> Function(int amountInr) onSubmit;

  const CashoutDialog({
    super.key,
    required this.availableInr,
    required this.onSubmit,
  });

  @override
  State<CashoutDialog> createState() => _CashoutDialogState();
}

class _CashoutDialogState extends State<CashoutDialog> {
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.availableInr.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    final text = _amountController.text.trim();
    final amount = int.tryParse(text);

    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid positive amount');
      return;
    }

    if (amount > widget.availableInr) {
      setState(() => _errorMessage =
          'Amount cannot exceed available earnings (₹${widget.availableInr})');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await widget.onSubmit(amount);
      if (mounted) {
        Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      title: const Row(
        children: [
          Icon(Icons.payments_outlined, color: AppColors.teal),
          SizedBox(width: 8),
          Text(
            'Request Cash-Out',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.12),
              borderRadius: AppRadii.badge,
              border: Border.all(color: AppColors.amber.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.science, size: 16, color: AppColors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Test Mode: Payout simulation. No real money moves from or to your bank account.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Available for Cash-Out: ₹${widget.availableInr}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '₹ ',
              labelText: 'Cash-out Amount',
              border: OutlineInputBorder(borderRadius: AppRadii.button),
              errorText: _errorMessage,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              if (widget.availableInr >= 250)
                ActionChip(
                  label: const Text('₹250'),
                  onPressed: () =>
                      setState(() => _amountController.text = '250'),
                ),
              if (widget.availableInr >= 500)
                ActionChip(
                  label: const Text('₹500'),
                  onPressed: () =>
                      setState(() => _amountController.text = '500'),
                ),
              ActionChip(
                label: const Text('All Available'),
                onPressed: () => setState(
                    () => _amountController.text = widget.availableInr.toString()),
              ),
            ],
          ),
        ],
      ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.slate)),
        ),
        WButton(
          label: 'Request Cash-Out',
          isLoading: _isLoading,
          onPressed: _validateAndSubmit,
          backgroundColor: AppColors.teal,
        ),
      ],
    );
  }
}
