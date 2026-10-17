import 'package:flutter/material.dart';
import 'package:warmpath_app/core/theme.dart';

class VerifiedBadge extends StatelessWidget {
  final String label;

  const VerifiedBadge({super.key, this.label = "Verified"});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: WarmPathColors.successGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WarmPathColors.successGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 13, color: WarmPathColors.successGreen),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: WarmPathColors.successGreen,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
