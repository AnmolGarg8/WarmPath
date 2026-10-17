class GiverBandInfo {
  final String giverId;
  final String currentBand; // 'Rising', 'Trusted', 'Top Rated'
  final double smoothedAverage;
  final int ratedSessionsCount;
  final double completionRate;
  final double payoutShare;
  final String? nextBand;
  final String progressNotes;

  const GiverBandInfo({
    required this.giverId,
    required this.currentBand,
    required this.smoothedAverage,
    required this.ratedSessionsCount,
    required this.completionRate,
    required this.payoutShare,
    this.nextBand,
    required this.progressNotes,
  });

  factory GiverBandInfo.fromJson(Map<String, dynamic> json) {
    return GiverBandInfo(
      giverId: json['giver_id']?.toString() ?? '',
      currentBand: json['current_band']?.toString() ?? 'Rising',
      smoothedAverage: (json['smoothed_average'] as num?)?.toDouble() ?? 4.0,
      ratedSessionsCount: json['rated_sessions_count'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 1.0,
      payoutShare: (json['payout_share'] as num?)?.toDouble() ?? 0.60,
      nextBand: json['next_band']?.toString(),
      progressNotes: json['progress_notes']?.toString() ?? '',
    );
  }
}

class RatingSummary {
  final String giverId;
  final String currentBand;
  final double smoothedAverage;
  final int ratedSessionsCount;
  final double completionRate;
  final Map<String, int> distribution;
  final List<Map<String, dynamic>> recentReviews;

  const RatingSummary({
    required this.giverId,
    required this.currentBand,
    required this.smoothedAverage,
    required this.ratedSessionsCount,
    required this.completionRate,
    required this.distribution,
    required this.recentReviews,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      giverId: json['giver_id']?.toString() ?? '',
      currentBand: json['current_band']?.toString() ?? 'Rising',
      smoothedAverage: (json['smoothed_average'] as num?)?.toDouble() ?? 4.0,
      ratedSessionsCount: json['rated_sessions_count'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 1.0,
      distribution: (json['distribution'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)) ?? {},
      recentReviews: (json['recent_reviews'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
    );
  }
}
