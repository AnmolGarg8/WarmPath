// allow-mock-file: guided demo, simulated and labelled

/// Configuration constants mirroring the exact backend formulas and thresholds
/// defined in PROJECT_CONTEXT section 6.
class DemoConfig {
  // --- Heuristic Matching Weights ---
  static const double weightExpertiseFit = 0.35;
  static const double weightIntentFit = 0.25;
  static const double weightAffinity = 0.15;
  static const double weightAvailability = 0.10;
  static const double weightRating = 0.10;
  static const double weightResponseOdds = 0.05;

  // --- Rating Smoothing Prior (Bayesian / m-estimate) ---
  static const double ratingPriorMean = 4.0;
  static const int ratingPriorWeight = 5;

  /// Pure formula for smoothed rating:
  /// smoothed = (priorWeight * priorMean + sum(ratings)) / (priorWeight + count)
  static double calculateSmoothedRating(List<double> ratings) {
    if (ratings.isEmpty) return ratingPriorMean;
    final double sum = ratings.reduce((a, b) => a + b);
    return (ratingPriorWeight * ratingPriorMean + sum) /
        (ratingPriorWeight + ratings.length);
  }

  // --- Bands, Thresholds, and Payout Shares ---
  // Rising
  static const int bandRisingMinSessions = 0;
  static const double bandRisingMinRating = 0.0;
  static const double bandRisingMinCompletionRate = 0.70;
  static const double bandRisingPayoutShare = 0.60; // 60%

  // Trusted
  static const int bandTrustedMinSessions = 10;
  static const double bandTrustedMinRating = 4.3;
  static const double bandTrustedMinCompletionRate = 0.80;
  static const double bandTrustedPayoutShare = 0.70; // 70%

  // Top Rated
  static const int bandTopRatedMinSessions = 25;
  static const double bandTopRatedMinRating = 4.7;
  static const double bandTopRatedMinCompletionRate = 0.90;
  static const double bandTopRatedPayoutShare = 0.80; // 80%

  // --- Plans and Reach ---
  static const DemoPlan campusPlan = DemoPlan(
    id: 'campus',
    name: 'Campus',
    priceInr: 0,
    credits: 0,
    creditUnitValueInr: 0.0,
    reachesBands: ['Rising (Own College Only)'],
    bookingHorizonDays: 3,
    priorityLevel: 1,
    description: 'Free forever for own-college alumni and peer connections.',
  );

  static const DemoPlan standardPlan = DemoPlan(
    id: 'standard',
    name: 'Standard',
    priceInr: 299,
    credits: 1,
    creditUnitValueInr: 299.0,
    reachesBands: ['Rising'],
    bookingHorizonDays: 7,
    priorityLevel: 1,
    description: 'Unlocks verified Rising alumni across any institution.',
  );

  static const DemoPlan highPlan = DemoPlan(
    id: 'high',
    name: 'High',
    priceInr: 499,
    credits: 2,
    creditUnitValueInr: 249.5,
    reachesBands: ['Rising', 'Trusted'],
    bookingHorizonDays: 14,
    priorityLevel: 2,
    description: 'Access Trusted mentors with 2x faster response guarantee.',
  );

  static const DemoPlan premiumPlan = DemoPlan(
    id: 'premium',
    name: 'Premium',
    priceInr: 899,
    credits: 4,
    creditUnitValueInr: 224.75,
    reachesBands: ['Rising', 'Trusted', 'Top Rated', 'Founders & Recruiters'],
    bookingHorizonDays: 30,
    priorityLevel: 3,
    description: 'All bands including Top Rated leaders, founders, and recruiters.',
  );

  static const List<DemoPlan> allPlans = [
    campusPlan,
    standardPlan,
    highPlan,
    premiumPlan,
  ];

  // --- Timers & Thresholds ---
  static const int disputeWindowHours = 48;
  static const int noReplyRefundHours = 72;
  static const int minimumCallOverlapMinutes = 5;

  // --- Trust & Daily Request Limits ---
  static const Map<String, int> dailyLimitsByTrustLevel = {
    'new': 1,
    'basic': 3,
    'verified': 5,
    'trusted': 10,
  };
}

class DemoPlan {
  final String id;
  final String name;
  final int priceInr;
  final int credits;
  final double creditUnitValueInr;
  final List<String> reachesBands;
  final int bookingHorizonDays;
  final int priorityLevel;
  final String description;

  const DemoPlan({
    required this.id,
    required this.name,
    required this.priceInr,
    required this.credits,
    required this.creditUnitValueInr,
    required this.reachesBands,
    required this.bookingHorizonDays,
    required this.priorityLevel,
    required this.description,
  });
}
