import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/core/api/app_exception.dart';

void main() {
  group('AppException Error Mapping Tests', () {
    test('Maps connectionTimeout to NetworkException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/me'),
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timed out',
      );

      final appException = AppException.fromDioError(dioError);
      expect(appException, isA<NetworkException>());
      expect(appException.code, equals('network_error'));
    });

    test('Maps institution_not_supported response to InstitutionNotSupportedException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/auth/request-otp'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/request-otp'),
          statusCode: 422,
          data: {
            'error': {
              'code': 'institution_not_supported',
              'message': 'Your institution is not registered with WarmPath.',
              'details': {'domain': 'unsupported.edu'},
            }
          },
        ),
      );

      final appException = AppException.fromDioError(dioError);
      expect(appException, isA<InstitutionNotSupportedException>());
      expect(appException.code, equals('institution_not_supported'));
      expect(appException.message, contains('Your institution is not registered'));
    });

    test('Maps 401 unauthorized status code to UnauthorizedException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/me'),
          statusCode: 401,
          data: {
            'error': {
              'code': 'unauthorized',
              'message': 'Invalid token',
            }
          },
        ),
      );

      final appException = AppException.fromDioError(dioError);
      expect(appException, isA<UnauthorizedException>());
      expect(appException.statusCode, equals(401));
    });

    test('Maps 429 rate limit exceeded to RateLimitException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/reports'),
        response: Response(
          requestOptions: RequestOptions(path: '/reports'),
          statusCode: 429,
          data: {
            'error': {
              'code': 'rate_limit_exceeded',
              'message': 'Daily outreach limit reached',
            }
          },
        ),
      );

      final appException = AppException.fromDioError(dioError);
      expect(appException, isA<RateLimitException>());
      expect(appException.statusCode, equals(429));
    });

    test('Maps 500 server error to ServerException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/me'),
          statusCode: 500,
          data: {
            'error': {
              'code': 'internal_server_error',
              'message': 'Internal database failure',
            }
          },
        ),
      );

      final appException = AppException.fromDioError(dioError);
      expect(appException, isA<ServerException>());
      expect(appException.statusCode, equals(500));
    });
  });
}
