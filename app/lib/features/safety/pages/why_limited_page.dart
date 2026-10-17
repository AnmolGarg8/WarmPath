import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../../core/widgets/w_card.dart';
import '../safety_providers.dart';

class WhyLimitedPage extends ConsumerWidget {
  const WhyLimitedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustAsync = ref.watch(meTrustProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Why Am I Limited?'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: trustAsync.when(
          data: (data) {
            final trustLevel = (data['trust_level'] ?? 'new').toString();
            final limit = data['requests_per_day_limit'] ?? 3;
            final remaining = data['requests_per_day_remaining'] ?? 3;
            final canPostJobs = data['can_post_jobs'] == true;
            final messagesReviewedFirst = data['messages_reviewed_first'] == true;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trust Level Summary Card
                WCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getLevelColor(trustLevel).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getLevelIcon(trustLevel),
                              color: _getLevelColor(trustLevel),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getLevelTitle(trustLevel),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getLevelSubtitle(trustLevel),
                                  style: const TextStyle(fontSize: 13, color: AppColors.slate),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      // Quota progress indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily Outreach Quota',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            '$remaining of $limit remaining',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: remaining > 0 ? AppColors.teal : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: limit > 0 ? (remaining / limit).clamp(0.0, 1.0) : 0,
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            remaining > 0 ? AppColors.teal : Colors.red,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            canPostJobs ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: canPostJobs ? AppColors.teal : AppColors.slate,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            canPostJobs
                                ? 'Can post opportunities'
                                : 'Opportunity posting requires verified status',
                            style: const TextStyle(fontSize: 12, color: AppColors.slate),
                          ),
                        ],
                      ),
                      if (messagesReviewedFirst) ...[
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.amber),
                            SizedBox(width: 6),
                            Text(
                              'Outreach messages are reviewed prior to delivery',
                              style: TextStyle(fontSize: 12, color: AppColors.amber),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Plain Language Principles
                const Text(
                  'Community Safety Principles',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                const WCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Why are limits in place?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Alumni and industry advisors volunteer their valuable time. '
                        'Limits prevent copy-paste spam and ensure every connection request is intentional, relevant, and thoughtful.',
                        style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.4),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '2. How are limits determined?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Privileges scale automatically as you establish trust on WarmPath. '
                        'Verifying your institutional email, completing sessions on time, and receiving respectful ratings gradually unlocks higher limits.',
                        style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.4),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '3. Do college rankings affect my limits?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Never. WarmPath strictly rejects college prestige tiers. '
                        'Trust is earned through verified identity, punctuality, and community ratings—every student and alumnus starts on an equal, merit-based foundation.',
                        style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
          loading: () => const Column(
            children: [
              WCard(child: SkeletonBox(width: double.infinity, height: 140)),
              SizedBox(height: 16),
              WCard(child: SkeletonBox(width: double.infinity, height: 200)),
            ],
          ),
          error: (err, _) => ErrorState(
            message: 'Unable to retrieve trust parameters: $err',
            onRetry: () => ref.refresh(meTrustProvider),
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'established':
        return AppColors.teal;
      case 'verified':
        return AppColors.deepIndigo;
      case 'restricted':
        return Colors.red;
      case 'new':
      default:
        return AppColors.slate;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toLowerCase()) {
      case 'established':
        return Icons.workspace_premium_rounded;
      case 'verified':
        return Icons.verified_user_rounded;
      case 'restricted':
        return Icons.gavel_rounded;
      case 'new':
      default:
        return Icons.person_outline_rounded;
    }
  }

  String _getLevelTitle(String level) {
    switch (level.toLowerCase()) {
      case 'established':
        return 'Established Member';
      case 'verified':
        return 'Verified Campus Member';
      case 'restricted':
        return 'Account Under Review';
      case 'new':
      default:
        return 'New Member';
    }
  }

  String _getLevelSubtitle(String level) {
    switch (level.toLowerCase()) {
      case 'established':
        return 'High reputation and completion rate';
      case 'verified':
        return 'Institutional affiliation verified';
      case 'restricted':
        return 'Temporarily limited by safety moderation';
      case 'new':
      default:
        return 'Standard initial safety quota';
    }
  }
}
