import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

// Re-export AppException for convenience
export 'app_exception.dart';

typedef LogoutCallback = void Function();

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  late final String baseUrl;
  LogoutCallback? onLogout;
  bool _isRefreshing = false;

  DioClient._internal() {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      baseUrl = envBaseUrl;
    } else if (kIsWeb) {
      baseUrl = 'http://localhost:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      baseUrl = 'http://10.0.2.2:8000';
    } else {
      baseUrl = 'http://localhost:8000';
    }

    dio = Dio(BaseOptions(
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
        // Attach JWT access token if available
        final token = await SecureStorageService.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Check if 401 Unauthorized
        if (error.response?.statusCode == 401) {
          // If the request was to refresh itself or login, don't attempt refresh
          final path = error.requestOptions.path;
          if (path.contains('/auth/refresh') ||
              path.contains('/auth/verify-otp') ||
              path.contains('/auth/request-otp')) {
            await SecureStorageService.clearAll();
            onLogout?.call();
            return handler.reject(error);
          }

          if (!_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshToken = await SecureStorageService.getRefreshToken();
              if (refreshToken != null && refreshToken.isNotEmpty) {
                // Perform token refresh using isolated Dio instance
                final refreshDio = Dio(BaseOptions(
                  baseUrl: baseUrl,
                  headers: {'Content-Type': 'application/json'},
                ));

                final refreshResponse = await refreshDio.post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );

                if (refreshResponse.statusCode == 200 && refreshResponse.data is Map) {
                  final data = refreshResponse.data as Map<String, dynamic>;
                  final newAccessToken = data['access_token']?.toString();
                  final newRefreshToken = data['refresh_token']?.toString();

                  if (newAccessToken != null && newRefreshToken != null) {
                    await SecureStorageService.saveTokens(
                      accessToken: newAccessToken,
                      refreshToken: newRefreshToken,
                    );

                    _isRefreshing = false;

                    // Retry original request with newly acquired access token
                    final retryOptions = error.requestOptions;
                    retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                    final retryResponse = await dio.fetch(retryOptions);
                    return handler.resolve(retryResponse);
                  }
                }
              }
            } catch (_) {
              // Refresh failed
            } finally {
              _isRefreshing = false;
            }

            // On failure, clear all tokens and trigger logout
            await SecureStorageService.clearAll();
            onLogout?.call();
          }
        }

        // Map into AppException and reject
        return handler.reject(error);
      },
    ));
  }
}

// Global factory function for existing consumers
Dio createDioClient() {
  return DioClient().dio;
}
