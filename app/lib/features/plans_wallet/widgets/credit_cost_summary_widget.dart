/// Shared Credit Cost Summary Widget for WarmPath student booking & request flows.
/// Exported via the public barrel file lib/features/plans_wallet/plans_wallet.dart.
/// Owner: M4
library;

import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/band_badge.dart';

class CreditCostSummaryWidget extends StatelessWidget {
  final String giverName;
  final String giverBand;
  final bool isOwnCollege;
  final int availableCredits;
  final int requiredCredits;
  final VoidCallback? onUpgradeTap;

  const CreditCostSummaryWidget({
    super.key,
    required this.giverName,
    this.giverBand = 'Rising',
    required this.isOwnCollege,
    required this.availableCredits,
    this.requiredCredits = 1,
    this.onUpgradeTap,
  });

  bool get hasSufficientCredits => availableCredits >= requiredCredits;

  @override
  Widget build(BuildContext context) {
    if (isOwnCollege) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withOpacity(0.08),
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school,
                color: AppColors.successGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '0 Credits',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius: AppRadii.badge,
                        ),
                        child: const Text(
                          'FREE ON CAMPUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mentorship with $giverName is 100% free because you share the same alma mater.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Cross-college connection
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: hasSufficientCredits
              ? AppColors.teal.withOpacity(0.3)
              : AppColors.primaryAction.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: AppColors.textDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$requiredCredits Cross-College Credit',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              BandBadge(band: giverBand),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$giverName is from another institution. One credit is reserved upon request and only consumed when the session completes.',
            style: const TextStyle(fontSize: 12, color: AppColors.slate),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: hasSufficientCredits
                  ? AppColors.teal.withOpacity(0.08)
                  : AppColors.primaryAction.withOpacity(0.08),
              borderRadius: AppRadii.badge,
            ),
            child: Row(
              children: [
                Icon(
                  hasSufficientCredits
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 16,
                  color: hasSufficientCredits
                      ? AppColors.teal
                      : AppColors.primaryAction,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasSufficientCredits
                        ? 'Wallet balance: $availableCredits credit(s) available.'
                        : 'You have $availableCredits credits. Upgrade to standard/high plan to connect.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasSufficientCredits
                          ? AppColors.teal
                          : AppColors.primaryAction,
                    ),
                  ),
                ),
                if (!hasSufficientCredits && onUpgradeTap != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onUpgradeTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAction,
                        borderRadius: AppRadii.badge,
                      ),
                      child: const Text(
                        'Upgrade',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
