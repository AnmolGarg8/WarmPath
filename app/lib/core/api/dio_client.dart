import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class AppException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final dynamic details;

  AppException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'AppException(code: $code, message: $message, statusCode: $statusCode)';
}

Dio createDioClient() {
  const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await SecureStorageService.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException error, handler) {
      if (error.response?.data is Map) {
        final errorPayload = error.response!.data['error'];
        if (errorPayload is Map) {
          throw AppException(
            code: errorPayload['code']?.toString() ?? 'unknown_error',
            message: errorPayload['message']?.toString() ?? 'An error occurred',
            statusCode: error.response?.statusCode,
            details: errorPayload['details'],
          );
        }
      }
      return handler.next(error);
    },
  ));

  return dio;
}
