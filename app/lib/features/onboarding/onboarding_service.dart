import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import 'onboarding_models.dart';

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

class OnboardingService {
  final Dio _dio;

  OnboardingService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<ResumeProfile> getProfile() async {
    try {
      final response = await _dio.get('/resume/profile');
      if (response.data is Map<String, dynamic>) {
        return ResumeProfile.fromJson(response.data as Map<String, dynamic>);
      } else if (response.data is Map) {
        return ResumeProfile.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
      return const ResumeProfile();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data['error'];
        if (err is Map) {
          throw AppException(
            code: err['code']?.toString() ?? 'unknown_error',
            message: err['message']?.toString() ?? 'An error occurred',
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

  Future<StudentIntent> getIntent() async {
    try {
      final response = await _dio.get('/me/intent');
      if (response.data is Map<String, dynamic>) {
        return StudentIntent.fromJson(response.data as Map<String, dynamic>);
      } else if (response.data is Map) {
        return StudentIntent.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
      return const StudentIntent();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data['error'];
        if (err is Map) {
          throw AppException(
            code: err['code']?.toString() ?? 'unknown_error',
            message: err['message']?.toString() ?? 'An error occurred',
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

  Future<void> saveIntent(String intent) async {
    try {
      await _dio.put('/me/intent', data: {'intent': intent});
    } on AppException {
      rethrow;
    } on DioException catch (e) {
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
