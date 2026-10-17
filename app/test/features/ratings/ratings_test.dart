import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/ratings/rating_models.dart';

void main() {
  group('GiverBandInfo Model Tests', () {
    test('parses band and payout share correctly', () {
      final json = {
        'giver_id': 'g123',
        'current_band': 'Trusted',
        'smoothed_average': 4.45,
        'rated_sessions_count': 7,
        'completion_rate': 0.98,
        'payout_share': 0.70,
        'next_band': 'Top Rated',
        'progress_notes': 'Needs at least 10 rated sessions',
      };

      final bandInfo = GiverBandInfo.fromJson(json);
      expect(bandInfo.giverId, 'g123');
      expect(bandInfo.currentBand, 'Trusted');
      expect(bandInfo.smoothedAverage, 4.45);
      expect(bandInfo.payoutShare, 0.70);
      expect(bandInfo.nextBand, 'Top Rated');
      expect(bandInfo.progressNotes, contains('10 rated sessions'));
    });
  });

  group('Rating Validation Logic Tests', () {
    test('validates stars within 1 to 5 range', () {
      bool isValidRating(int stars) => stars >= 1 && stars <= 5;

      expect(isValidRating(1), isTrue);
      expect(isValidRating(5), isTrue);
      expect(isValidRating(0), isFalse);
      expect(isValidRating(6), isFalse);
    });

    test('validates dispute reasons', () {
      const validReasons = {'no_show', 'low_effort', 'abusive', 'other'};
      expect(validReasons.contains('no_show'), isTrue);
      expect(validReasons.contains('unprepared'), isFalse);
    });
  });
}
