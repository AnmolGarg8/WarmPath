/// Giver earnings model and payout shares explained in plain language.
/// Owner: M4
library;

class EarningsModel {
  final int pendingInr; // In dispute window (48h)
  final int availableInr; // Ready for cash-out
  final int paidOutInr; // Already transferred
  final String ratingBand; // Rising, Trusted, Top Rated
  final int payoutSharePct; // 60%, 70%, 80%
  final int availableCredits;

  const EarningsModel({
    required this.pendingInr,
    required this.availableInr,
    required this.paidOutInr,
    required this.ratingBand,
    required this.payoutSharePct,
    required this.availableCredits,
  });

  bool get canCashout => availableInr > 0;

  String get plainRatingBandShare {
    switch (ratingBand.toLowerCase()) {
      case 'top rated':
      case 'top_rated':
        return 'Top Rated mentors receive an 80% payout share on cross-college sessions, recognizing top-tier mentorship.';
      case 'trusted':
        return 'Trusted mentors receive a 70% payout share. Complete more verified sessions with high ratings to unlock Top Rated (80%).';
      case 'rising':
      default:
        return 'Rising mentors receive a 60% payout share. Maintain high ratings across your first 5 sessions to reach Trusted (70%).';
    }
  }

  String get plainDisputeNotice =>
      'Funds are held for 48 hours following session completion to allow student dispute resolution, then automatically move to available balance.';

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    final band = json['rating_band']?.toString() ?? 'Rising';
    int defaultShare = 60;
    if (band.toLowerCase().contains('top')) {
      defaultShare = 80;
    } else if (band.toLowerCase().contains('trusted')) {
      defaultShare = 70;
    }

    return EarningsModel(
      pendingInr: (json['pending_inr'] as num?)?.toInt() ?? 0,
      availableInr: (json['available_inr'] as num?)?.toInt() ?? 0,
      paidOutInr: (json['paid_out_inr'] as num?)?.toInt() ?? 0,
      ratingBand: band,
      payoutSharePct:
          (json['payout_share_pct'] as num?)?.toInt() ?? defaultShare,
      availableCredits: (json['available_credits'] as num?)?.toInt() ?? 0,
    );
  }

  static EarningsModel empty() {
    return const EarningsModel(
      pendingInr: 0,
      availableInr: 0,
      paidOutInr: 0,
      ratingBand: 'Rising',
      payoutSharePct: 60,
      availableCredits: 0,
    );
  }
}
