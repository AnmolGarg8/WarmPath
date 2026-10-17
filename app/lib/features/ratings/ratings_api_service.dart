import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import 'rating_models.dart';

class RatingsApiService {
  final Dio _dio;

  static GiverBandInfo _demoBand = const GiverBandInfo(
    giverId: 'usr_student_demo',
    currentBand: 'Trusted',
    smoothedAverage: 4.85,
    ratedSessionsCount: 18,
    completionRate: 0.95,
    payoutShare: 0.70,
    nextBand: 'Top Rated',
    progressNotes: 'Need 10+ sessions (18 completed) and 4.6+ average (4.85 achieved) with 90%+ completion (95% achieved). Approaching Top Rated tier!',
  );

  RatingsApiService([Dio? dio]) : _dio = dio ?? createDioClient();

  Future<void> submitRating({
    required String sessionId,
    required int stars,
    String? reason,
    List<String> tags = const [],
  }) async {
    try {
      await _dio.post(
        '/sessions/$sessionId/rating',
        data: {
          'stars': stars,
          'reason': reason,
          'tags': tags,
        },
      );
    } catch (_) {
      // In-memory demo rating recording
      final newCount = _demoBand.ratedSessionsCount + 1;
      final newAvg = ((_demoBand.smoothedAverage * _demoBand.ratedSessionsCount) + stars) / newCount;
      _demoBand = GiverBandInfo(
        giverId: _demoBand.giverId,
        currentBand: newAvg >= 4.8 ? 'Top Rated' : 'Trusted',
        smoothedAverage: double.parse(newAvg.toStringAsFixed(2)),
        ratedSessionsCount: newCount,
        completionRate: 0.96,
        payoutShare: newAvg >= 4.8 ? 0.80 : 0.70,
        nextBand: newAvg >= 4.8 ? null : 'Top Rated',
        progressNotes: newAvg >= 4.8
            ? 'Congratulations! Highest tier achieved (Top Rated: 80% payout share).'
            : 'Rated $stars stars! Progression score updated.',
      );
    }
  }

  Future<void> submitRequestQuality({
    required String sessionId,
    required int stars,
    String? note,
  }) async {
    try {
      await _dio.post(
        '/sessions/$sessionId/request-quality',
        data: {
          'stars': stars,
          'note': note,
        },
      );
    } catch (_) {}
  }

  Future<GiverBandInfo> getMeBand() async {
    try {
      final response = await _dio.get('/me/band');
      return GiverBandInfo.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return _demoBand;
    }
  }

  Future<RatingSummary> getRatingSummary(String giverId) async {
    try {
      final response = await _dio.get('/givers/$giverId/rating-summary');
      return RatingSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return const RatingSummary(
        giverId: 'alumnus_aarav',
        currentBand: 'Top Rated',
        smoothedAverage: 4.90,
        ratedSessionsCount: 34,
        completionRate: 0.98,
        distribution: {'5': 30, '4': 4, '3': 0, '2': 0, '1': 0},
        recentReviews: [
          {
            'stars': 5,
            'reason': 'Extremely helpful advice on Azure distributed systems and mock interview rounds!',
            'tags': ['Actionable Advice', 'Deep Domain Knowledge', 'Helpful'],
          },
          {
            'stars': 5,
            'reason': 'Great mentor. Helped me structure my resume for Microsoft referrals.',
            'tags': ['Clear Communication', 'Inspiring'],
          },
        ],
      );
    }
  }

  Future<void> openDispute({
    required String sessionId,
    required String reason,
    required String details,
  }) async {
    try {
      await _dio.post(
        '/sessions/$sessionId/dispute',
        data: {
          'reason': reason,
          'details': details,
        },
      );
    } catch (_) {}
  }
}
