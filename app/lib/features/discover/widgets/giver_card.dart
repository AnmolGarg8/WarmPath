import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/band_badge.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../../core/widgets/w_card.dart';
import '../models/discover_models.dart';

class GiverCard extends StatelessWidget {
  final RecommendationItemData item;
  final VoidCallback? onTap;

  const GiverCard({
    super.key,
    required this.item,
    this.onTap,
  });

  String _getPlanNeededText(String? reason) {
    if (reason == 'expert_plan_required') {
      return 'Expert Mentor: Premium Plan required.';
    }
    return 'Cross-College Mentor: Standard or Premium Plan required.';
  }

  Widget _buildVerificationBadge(String badgeStr) {
    final role = badgeStr.startsWith('Verified ')
        ? badgeStr.substring('Verified '.length)
        : badgeStr;
    return VerifiedBadge(role: role);
  }

  Widget _buildBandBadge(GiverCardData giver) {
    if (giver.ratingSummary.totalSessions < 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.bandRising.withOpacity(0.12),
          borderRadius: AppRadii.badge,
          border: Border.all(color: AppColors.bandRising.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_up, size: 14, color: AppColors.bandRising),
            SizedBox(width: 4),
            Text(
              'New giver',
              style: TextStyle(
                color: AppColors.bandRising,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    if (giver.band.isNotEmpty) {
      return BandBadge(band: giver.band);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final giver = item.giver;
    final isLocked = item.locked;

    if (isLocked) {
      final initial = giver.fullName.isNotEmpty ? giver.fullName[0].toUpperCase() : 'M';
      return Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: WCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryAction.withOpacity(0.12),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryAction,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$initial.',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          giver.headline,
                          style: const TextStyle(fontSize: 13, color: AppColors.slate),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, size: 20, color: AppColors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getPlanNeededText(item.lockReason),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAction,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => context.push('/plans-wallet'),
                      child: const Text('Upgrade', style: TextStyle(fontSize: 12, color: AppColors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: WCard(
        onTap: onTap ?? () => context.push('/givers/${giver.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Online dot, Badges, Capacity - Wrapped to prevent overflow at 320/360dp
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (giver.availabilitySummary.online)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Online now',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                for (final badge in giver.badges)
                  _buildVerificationBadge(badge),
                _buildBandBadge(giver),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${giver.availabilitySummary.capacityLeft} slots left',
                    style: const TextStyle(fontSize: 10, color: AppColors.slate, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Name and Headline
            Text(
              giver.fullName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              giver.headline,
              style: const TextStyle(fontSize: 13, color: AppColors.slate),
            ),
            const SizedBox(height: 8),

            // Rating Summary (smoothed average, or "New" if totalSessions < 5)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                const Icon(Icons.star, size: 15, color: AppColors.amber),
                Text(
                  giver.ratingSummary.totalSessions < 5
                      ? 'New'
                      : giver.ratingSummary.smoothedAvg.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                Text(
                  ' (${giver.ratingSummary.totalSessions} sessions)',
                  style: const TextStyle(fontSize: 11, color: AppColors.slate),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Plain-Language Explainability why_lines
            if (item.whyLines.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: item.whyLines.map((line) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, size: 13, color: AppColors.teal),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              line,
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Offers Chips
            if (giver.offers.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: giver.offers.take(3).map((offer) {
                  final label = offer.replaceAll('_', ' ');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.deepIndigo.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 11, color: AppColors.deepIndigo, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
