import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class TrustNotice extends StatelessWidget {
  final String title;
  final String message;
  final Widget? action;
  final IconData icon;

  const TrustNotice({
    super.key,
    this.title = 'Verified & Protected',
    required this.message,
    this.action,
    this.icon = Icons.verified_user_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.08),
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.teal.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slate,
              height: 1.4,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 10),
            action!,
          ],
        ],
      ),
    );
  }
}
