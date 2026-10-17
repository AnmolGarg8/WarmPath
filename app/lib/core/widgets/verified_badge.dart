import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class VerifiedBadge extends StatelessWidget {
  final String role; // 'Student', 'Alumnus', 'Employer', 'Expert'

  const VerifiedBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.12),
        borderRadius: AppRadii.badge,
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 13, color: AppColors.teal),
          const SizedBox(width: 4),
          Text(
            'Verified $role',
            style: const TextStyle(
              color: AppColors.teal,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
