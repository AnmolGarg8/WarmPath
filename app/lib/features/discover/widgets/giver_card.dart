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

  @override
  Widget build(BuildContext context) {
    final giver = item.giver;
    final isLocked = item.locked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: WCard(
        onTap: isLocked ? null : onTap ?? () => context.push('/givers/${giver.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Online dot, Badges, Capacity
            Row(
              children: [
                if (giver.availabilitySummary.online) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.successGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Online now',
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                const VerifiedBadge(role: 'Alumnus'),
                const SizedBox(width: 8),
                BandBadge(band: giver.band),
                const Spacer(),
                if (!isLocked)
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

            // Rating Summary
            Row(
              children: [
                const Icon(Icons.star, size: 15, color: AppColors.amber),
                const SizedBox(width: 4),
                Text(
                  giver.ratingSummary.smoothedAvg.toStringAsFixed(1),
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
            if (giver.offers.isNotEmpty && !isLocked) ...[
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

            // Locked State Overlay Banner
            if (isLocked) ...[
              const SizedBox(height: 6),
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
                    const Expanded(
                      child: Text(
                        'Cross-College Mentor: Standard or Premium Plan required.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                    ),
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
          ],
        ),
      ),
    );
  }
}
