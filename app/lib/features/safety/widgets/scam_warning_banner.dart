import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';

class ScamWarningBanner extends StatelessWidget {
  final String action; // 'allow', 'warn', 'block', 'review'
  final List<String> flags;
  final String? customMessage;

  const ScamWarningBanner({
    super.key,
    required this.action,
    this.flags = const [],
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (action == 'allow' && flags.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSevere = action == 'block' || action == 'review';
    final bgColor = isSevere
        ? Colors.red.withOpacity(0.12)
        : AppColors.amber.withOpacity(0.14);
    final borderColor = isSevere
        ? Colors.red.withOpacity(0.4)
        : AppColors.amber.withOpacity(0.4);
    final iconColor = isSevere ? Colors.red : AppColors.amber;
    final textColor = isSevere ? const Color(0xFF991B1B) : const Color(0xFF92400E);

    String message = customMessage ?? _getMessageForFlags(flags, action);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.button,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSevere ? 'Safety Protection Triggered' : 'Community Safety Advisory',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMessageForFlags(List<String> flags, String action) {
    if (flags.contains('money_fee_fraud')) {
      return 'Never pay registration fees, security deposits, or placement charges. Legitimate alumni will never ask for payment outside WarmPath.';
    }
    if (flags.contains('off_platform_push')) {
      return 'Moving conversation to WhatsApp or Telegram violates community rules and voids payment protection.';
    }
    if (flags.contains('suspicious_link')) {
      return 'Caution: This message contains shortened or unverified links. Never enter your credentials on third-party sites.';
    }
    if (flags.contains('copy_paste_spam')) {
      return 'High volume identical outreach detected. Take time to craft thoughtful, personalized requests.';
    }
    if (action == 'block') {
      return 'This message has been blocked by WarmPath safety policies.';
    }
    return 'Our automated safety scanner identified potential policy violations. Please exercise caution.';
  }
}
