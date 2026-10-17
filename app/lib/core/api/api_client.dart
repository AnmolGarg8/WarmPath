import 'package:dio/dio.dart';
import 'package:warmpath_app/core/storage/secure_storage.dart';

class AppException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  AppException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => "AppException[$code]: $message";
}

class ApiClient {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  late final Dio dio;

  ApiClient({String baseUrl = defaultBaseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          final data = error.response?.data;
          if (data is Map<String, dynamic> && data['error'] != null) {
            final err = data['error'];
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: AppException(
                  code: err['code'] ?? 'unknown_error',
                  message: err['message'] ?? 'An error occurred',
                  details: err['details'] is Map<String, dynamic> ? err['details'] : null,
                ),
                response: error.response,
              ),
            );
          }
          return handler.next(error);
        },
      ),
    );
  }
}
