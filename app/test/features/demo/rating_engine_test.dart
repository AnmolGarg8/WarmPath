import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/demo/engine/contracts.dart';
import 'package:warmpath_app/features/demo/engine/rating_engine_impl.dart';

void main() {
  group('RatingEngine Tests (Pillar 3)', () {
    final engine = RatingEngineImpl();

    test('Exact Bayesian smoothing test: [5, 5, 4] gives 4.25', () {
      // Prior mean 4.0, prior weight 5:
      // smoothed = (5 * 4.0 + (5 + 5 + 4)) / (5 + 3) = 34 / 8 = 4.25
      final ratings = [5.0, 5.0, 4.0];
      final smoothed = engine.computeSmoothedRating(ratings);
      expect(smoothed, 4.25);
    });

    test('Empty ratings list defaults safely to prior mean 4.0', () {
      final smoothed = engine.computeSmoothedRating([]);
      expect(smoothed, 4.0);
    });

    test('Band thresholds correctly map to Rising, Trusted, and Top Rated', () {
      // Rising: 5 sessions, 4.5 rating
      final b1 = engine.getBand(
        completedSessions: 5,
        smoothedRating: 4.5,
        completionRate: 0.95,
      );
      expect(b1, GiverBand.rising);

      // Trusted: 15 sessions, 4.4 rating, 85% completion
      final b2 = engine.getBand(
        completedSessions: 15,
        smoothedRating: 4.4,
        completionRate: 0.85,
      );
      expect(b2, GiverBand.trusted);

      // Top Rated: 28 sessions, 4.8 rating, 92% completion
      final b3 = engine.getBand(
        completedSessions: 28,
        smoothedRating: 4.8,
        completionRate: 0.92,
      );
      expect(b3, GiverBand.topRated);
    });

    test('Payout calculations for 250 INR credit value yields exact 150, 175, 200', () {
      const double creditVal = 250.0;

      // Rising (60%): 250 * 0.60 = 150.0
      expect(engine.calculatePayout(creditVal, 'rising'), 150.0);

      // Trusted (70%): 250 * 0.70 = 175.0
      expect(engine.calculatePayout(creditVal, 'trusted'), 175.0);

      // Top Rated (80%): 250 * 0.80 = 200.0
      expect(engine.calculatePayout(creditVal, 'top rated'), 200.0);
    });

    test('Integrity Guard flags reciprocal 5-star swaps and dampens scores', () {
      final collusiveRatings = [
        RatingRecord(id: 'r1', raterId: 'user_x', rateeId: 'user_y', score: 5.0, feedback: '', timestamp: DateTime.now()),
        RatingRecord(id: 'r2', raterId: 'user_y', rateeId: 'user_x', score: 5.0, feedback: '', timestamp: DateTime.now()),
      ];

      final res = engine.checkRatingsIntegrity(collusiveRatings);
      expect(res.hasSuspiciousPattern, isTrue);
      expect(res.anomalyType, contains('Reciprocal'));
    });
  });
}
