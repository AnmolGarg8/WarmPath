import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import 'rating_models.dart';

class RatingsApiService {
  final Dio _dio;

  RatingsApiService([Dio? dio]) : _dio = dio ?? createDioClient();

  Future<void> submitRating({
    required String sessionId,
    required int stars,
    String? reason,
    List<String> tags = const [],
  }) async {
    await _dio.post(
      '/sessions/$sessionId/rating',
      data: {
        'stars': stars,
        'reason': reason,
        'tags': tags,
      },
    );
  }

  Future<void> submitRequestQuality({
    required String sessionId,
    required int stars,
    String? note,
  }) async {
    await _dio.post(
      '/sessions/$sessionId/request-quality',
      data: {
        'stars': stars,
        'note': note,
      },
    );
  }

  Future<GiverBandInfo> getMeBand() async {
    final response = await _dio.get('/me/band');
    return GiverBandInfo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RatingSummary> getRatingSummary(String giverId) async {
    final response = await _dio.get('/givers/$giverId/rating-summary');
    return RatingSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> openDispute({
    required String sessionId,
    required String reason,
    required String details,
  }) async {
    await _dio.post(
      '/sessions/$sessionId/dispute',
      data: {
        'reason': reason,
        'details': details,
      },
    );
  }
}
