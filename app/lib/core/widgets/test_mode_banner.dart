import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class TestModeBanner extends StatelessWidget {
  final String text;

  const TestModeBanner({
    super.key,
    this.text = 'Test mode: no real money moves',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.15),
        borderRadius: AppRadii.badge,
        border: Border.all(color: AppColors.amber.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.amber),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309), // Dark amber
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
