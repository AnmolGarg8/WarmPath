import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import 'discover_models.dart';

bool isNotImplemented(Object error) {
  if (error is AppException) {
    return error.code == 'module_not_implemented' || error.statusCode == 501;
  }
  if (error is DioException) {
    return error.response?.statusCode == 501;
  }
  final s = error.toString().toLowerCase();
  return s.contains('module_not_implemented') || s.contains('501');
}

class DiscoverService {
  final Dio _dio;

  DiscoverService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<RecommendationsResponse> getRecommendations({String scope = 'own_college'}) async {
    try {
      final response = await _dio.get(
        '/recommendations',
        queryParameters: {'scope': scope},
      );
      if (response.data is Map<String, dynamic>) {
        return RecommendationsResponse.fromJson(response.data as Map<String, dynamic>);
      } else if (response.data is Map) {
        return RecommendationsResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
      return const RecommendationsResponse(items: [], scope: 'own_college');
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data['error'];
        if (err is Map) {
          throw AppException(
            code: err['code']?.toString() ?? 'unknown_error',
            message: err['message']?.toString() ?? e.message ?? 'An error occurred',
            statusCode: e.response?.statusCode,
            details: err['details'],
          );
        }
      }
      if (e.response?.statusCode == 501) {
        throw AppException(
          code: 'module_not_implemented',
          message: 'Endpoint is scaffolded and pending module implementation.',
          statusCode: 501,
        );
      }
      rethrow;
    }
  }
}
