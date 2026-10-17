import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/band_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/skeleton_box.dart';
import '../../core/widgets/verified_badge.dart';
import '../../core/widgets/w_button.dart';
import '../../core/widgets/w_card.dart';
import 'discover_models.dart';
import 'discover_providers.dart';
import 'discover_service.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WarmPath Recommendations'),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(recommendationsProvider),
          ),
        ],
      ),
      body: recommendationsAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (error, _) {
          if (isNotImplemented(error)) {
            return const ErrorState(
              title: 'Feature Unavailable',
              message: 'This feature is not available yet',
            );
          }
          return ErrorState(
            title: 'Unable to Load Recommendations',
            message: error.toString(),
            onRetry: () => ref.invalidate(recommendationsProvider),
          );
        },
        data: (response) {
          if (response.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyState(
                      title: 'No Recommendations Found',
                      message: 'Upload your resume and state your intent to get matched with same-college alumni.',
                      icon: Icons.person_search_outlined,
                    ),
                    const SizedBox(height: 16),
                    WButton(
                      label: 'Upload Resume & Set Intent',
                      onPressed: () => context.push('/onboarding'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(recommendationsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: response.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = response.items[index];
                return _buildRecommendationCard(context, item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const WCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 90, height: 22),
                SizedBox(width: 8),
                SkeletonBox(width: 70, height: 22),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBox(width: 180, height: 18),
            SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 14),
            SizedBox(height: 12),
            SkeletonBox(width: 120, height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, RecommendationItem item) {
    final giver = item.giver;
    final isOnline = giver.availabilitySummary?.online ?? false;

    return WCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  giver.fullName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (isOnline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.successGreen),
                      SizedBox(width: 4),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              VerifiedBadge(role: giver.roleTitle ?? 'Alumnus'),
              const SizedBox(width: 8),
              BandBadge(band: giver.band),
            ],
          ),
          if (giver.headline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              giver.headline,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ],
          if (item.whyLines.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why this match:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...item.whyLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $line',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.deepIndigo,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (giver.skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: giver.skills.take(5).map((skill) {
                return Chip(
                  label: Text(
                    skill.toString(),
                    style: const TextStyle(fontSize: 11, color: AppColors.deepIndigo),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.surface,
                );
              }).toList(),
            ),
          ],
          if (item.locked) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: AppColors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.lockReason ?? 'Cross-college unlock required',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: WButton(
              label: item.locked ? 'Unlock' : 'Connect',
              onPressed: () {
                // Navigate to connect or plans
              },
            ),
          ),
        ],
      ),
    );
  }
}
