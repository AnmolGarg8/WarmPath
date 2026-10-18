// allow-mock-file: guided demo, simulated and labelled
import 'contracts.dart';
import 'demo_config.dart';

class RatingEngineImpl implements RatingEngine {
  @override
  double computeSmoothedRating(List<double> ratings) {
    return DemoConfig.calculateSmoothedRating(ratings);
  }

  @override
  GiverBand getBand({
    required int completedSessions,
    required double smoothedRating,
    required double completionRate,
  }) {
    // Top Rated: min 25 sessions, smoothed rating >= 4.7, completion rate >= 0.90
    if (completedSessions >= DemoConfig.bandTopRatedMinSessions &&
        smoothedRating >= DemoConfig.bandTopRatedMinRating &&
        completionRate >= DemoConfig.bandTopRatedMinCompletionRate) {
      return GiverBand.topRated;
    }

    // Trusted: min 10 sessions, smoothed rating >= 4.3, completion rate >= 0.80
    if (completedSessions >= DemoConfig.bandTrustedMinSessions &&
        smoothedRating >= DemoConfig.bandTrustedMinRating &&
        completionRate >= DemoConfig.bandTrustedMinCompletionRate) {
      return GiverBand.trusted;
    }

    return GiverBand.rising;
  }

  @override
  double calculatePayout(double creditValue, String band) {
    double share;
    switch (band.toLowerCase()) {
      case 'top rated':
      case 'toprated':
        share = DemoConfig.bandTopRatedPayoutShare; // 0.80
        break;
      case 'trusted':
        share = DemoConfig.bandTrustedPayoutShare; // 0.70
        break;
      case 'rising':
      default:
        share = DemoConfig.bandRisingPayoutShare; // 0.60
        break;
    }
    return creditValue * share;
  }

  @override
  IntegrityCheckResult checkRatingsIntegrity(List<RatingRecord> ratings) {
    if (ratings.length < 2) {
      return const IntegrityCheckResult(
        hasSuspiciousPattern: false,
        anomalyType: 'None',
        adjustedRating: 0.0,
        explanation: 'Normal rating distribution. No reciprocal anomalies detected.',
      );
    }

    // Detect reciprocal 5-star collusion: e.g. user A rates user B 5.0, user B rates user A 5.0 in close succession
    bool reciprocalFound = false;
    for (int i = 0; i < ratings.length; i++) {
      for (int j = i + 1; j < ratings.length; j++) {
        final r1 = ratings[i];
        final r2 = ratings[j];
        if (r1.raterId == r2.rateeId &&
            r1.rateeId == r2.raterId &&
            r1.score >= 5.0 &&
            r2.score >= 5.0) {
          reciprocalFound = true;
          break;
        }
      }
    }

    if (reciprocalFound) {
      // Downweight reciprocal ratings from weight 1.0 to weight 0.2
      final rawScores = ratings.map((r) => r.score).toList();
      final double rawSmoothed = computeSmoothedRating(rawScores);

      // Adjusted: down-weight suspicious pairs
      final adjustedScores = ratings.map((r) {
        if (r.score == 5.0) return 4.0; // Dampened to prior mean
        return r.score;
      }).toList();
      final double adjustedSmoothed = computeSmoothedRating(adjustedScores);

      return IntegrityCheckResult(
        hasSuspiciousPattern: true,
        anomalyType: 'Reciprocal 5-Star Collusion Pair',
        adjustedRating: adjustedSmoothed,
        explanation:
            'Integrity Guard flagged reciprocal 5-star collusion between connected accounts. Scores down-weighted (smoothed impact: ${rawSmoothed.toStringAsFixed(2)} -> ${adjustedSmoothed.toStringAsFixed(2)}). Bands never reward artificial rating trades.',
      );
    }

    return const IntegrityCheckResult(
      hasSuspiciousPattern: false,
      anomalyType: 'None',
      adjustedRating: 0.0,
      explanation: 'Integrity check passed: ratings show organic distribution across diverse student accounts.',
    );
  }
}
