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

    final res = await _dio.get(
      '/recommendations',
      queryParameters: queryParams,
    );

    return RecommendationsData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GiverCardData> getGiver(String id) async {
    final res = await _dio.get('/givers/$id');
    return GiverCardData.fromJson(res.data as Map<String, dynamic>);
  }
}
