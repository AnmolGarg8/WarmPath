import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_card.dart';
import '../../core/widgets/band_badge.dart';
import '../../core/widgets/error_state.dart';
import 'ratings_controller.dart';

class BandPage extends ConsumerWidget {
  const BandPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bandProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating Band & Earnings Share'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? ErrorState(
                  message: state.errorMessage!,
                  onRetry: () => ref.read(bandProvider.notifier).loadBandInfo(),
                )
              : state.bandInfo == null
                  ? const Center(child: Text('No band details found.'))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(bandProvider.notifier).loadBandInfo(),
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          // Top Tier Status Card
                          WCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                BandBadge(band: state.bandInfo!.currentBand),
                                const SizedBox(height: 12),
                                Text(
                                  '\${state.bandInfo!.smoothedAverage.toStringAsFixed(2)} ★',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Smoothed Bayesian Average',
                                  style: TextStyle(fontSize: 13, color: AppColors.slate),
                                ),
                                const Divider(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStat(
                                      label: 'Rated Sessions',
                                      value: '\${state.bandInfo!.ratedSessionsCount}',
                                    ),
                                    _buildStat(
                                      label: 'Completion',
                                      value: '\${(state.bandInfo!.completionRate * 100).toInt()}%',
                                    ),
                                    _buildStat(
                                      label: 'Payout Share',
                                      value: '\${(state.bandInfo!.payoutShare * 100).toInt()}%',
                                      color: AppColors.teal,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tier Progression Explanation Card
                          WCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.trending_up, color: AppColors.teal),
                                    const SizedBox(width: 8),
                                    Text(
                                      state.bandInfo!.nextBand != null
                                          ? 'Next Tier: \${state.bandInfo!.nextBand}'
                                          : 'Highest Tier Achieved',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  state.bandInfo!.progressNotes,
                                  style: const TextStyle(fontSize: 14, color: AppColors.slate, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Transparent Rules Card
                          WCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Tier Progression Rules',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• Rising (60% payout): New and developing mentors.\n'
                                  '• Trusted (70% payout): At least 5 rated sessions with smoothed average >= 4.2.\n'
                                  '• Top Rated (80% payout): At least 10 rated sessions, smoothed average >= 4.6, completion rate >= 90%.\n'
                                  '• Fair & Objective: Tiers depend solely on student ratings and reliability, never on college prestige.',
                                  style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStat({required String label, required String value, Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.slate),
        ),
      ],
    );
  }
}
