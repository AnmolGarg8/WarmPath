import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';

class SafetyRepository {
  final Dio _dio;

  SafetyRepository({Dio? dio}) : _dio = dio ?? createDioClient();

  /// Create a community safety report
  Future<Map<String, dynamic>> createReport({
    String? targetUserId,
    String? messageId,
    String? requestId,
    required String reason,
    String? details,
  }) async {
    try {
      final payload = <String, dynamic>{
        'reason': reason.trim(),
      };
      if (targetUserId != null && targetUserId.isNotEmpty) {
        payload['target_user_id'] = targetUserId;
      }
      if (messageId != null && messageId.isNotEmpty) {
        payload['message_id'] = messageId;
      }
      if (requestId != null && requestId.isNotEmpty) {
        payload['request_id'] = requestId;
      }
      if (details != null && details.trim().isNotEmpty) {
        payload['details'] = details.trim();
      }

      final response = await _dio.post('/reports', data: payload);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Block a user bidirectionally
  Future<Map<String, dynamic>> blockUser({
    required String blockedUserId,
    String? reason,
  }) async {
    try {
      final response = await _dio.post('/blocks', data: {
        'blocked_user_id': blockedUserId,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Unblock a previously blocked user
  Future<void> unblockUser(String userId) async {
    try {
      await _dio.delete('/blocks/$userId');
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Get current private trust level and daily quotas
  Future<Map<String, dynamic>> getMeTrust() async {
    try {
      final response = await _dio.get('/me/trust');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }
}
