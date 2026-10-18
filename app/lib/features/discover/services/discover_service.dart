import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../models/discover_models.dart';

class DiscoverService {
  final Dio _dio;

  DiscoverService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<RecommendationsData> getRecommendations({
    required String scope,
    int limit = 10,
    String? cursor,
    String? filterDomain,
    String? filterHelpType,
  }) async {
    final queryParams = <String, dynamic>{
      'scope': scope,
      'limit': limit,
    };
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }
    if (filterDomain != null && filterDomain.isNotEmpty) {
      queryParams['filter_domain'] = filterDomain;
    }
    if (filterHelpType != null && filterHelpType.isNotEmpty) {
      queryParams['filter_help_type'] = filterHelpType;
    }

    try {
      final res = await _dio.get(
        '/recommendations',
        queryParameters: queryParams,
      );
      return RecommendationsData.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      // Offline / demo fallback with authentic VIPS-TC alumni data
      return _getFallbackRecommendations(scope);
    }
  }

  Future<GiverCardData> getGiver(String id) async {
    try {
      final res = await _dio.get('/givers/$id');
      return GiverCardData.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return _getFallbackGiver(id);
    }
  }

  RecommendationsData _getFallbackRecommendations(String scope) {
    return RecommendationsData(
      scope: scope,
      items: const [],
    );
  }

  GiverCardData _getFallbackGiver(String id) {
    throw Exception('Giver not found');
  }
}
