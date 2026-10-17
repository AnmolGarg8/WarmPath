import 'package:dio/dio.dart';

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

  factory AppException.fromDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException(
        message: 'Unable to connect to WarmPath servers. Please check your internet connection.',
      );
    }

    final response = error.response;
    if (response != null && response.data is Map) {
      final data = response.data as Map;
      final errorPayload = data['error'];
      if (errorPayload is Map) {
        final code = errorPayload['code']?.toString() ?? 'unknown_error';
        final message = errorPayload['message']?.toString() ?? 'An error occurred';
        final details = errorPayload['details'];

        switch (code) {
          case 'institution_not_supported':
            return InstitutionNotSupportedException(
              message: message,
              details: details,
            );
          case 'unauthorized':
            return UnauthorizedException(message: message, details: details);
          case 'forbidden':
            return ForbiddenException(message: message, details: details);
          case 'not_found':
            return NotFoundException(message: message, details: details);
          case 'rate_limit_exceeded':
            return RateLimitException(message: message, details: details);
          case 'validation_error':
            return ValidationException(message: message, details: details);
          default:
            if (response.statusCode == 401) {
              return UnauthorizedException(message: message, details: details);
            }
            if (response.statusCode == 403) {
              return ForbiddenException(message: message, details: details);
            }
            if (response.statusCode == 404) {
              return NotFoundException(message: message, details: details);
            }
            if (response.statusCode == 429) {
              return RateLimitException(message: message, details: details);
            }
            if ((response.statusCode ?? 0) >= 500) {
              return ServerException(message: message, details: details);
            }
            return AppException(
              code: code,
              message: message,
              statusCode: response.statusCode,
              details: details,
            );
        }
      }
    }

    return AppException(
      code: 'unknown_error',
      message: error.message ?? 'An unexpected network error occurred',
      statusCode: response?.statusCode,
    );
  }
}

class InstitutionNotSupportedException extends AppException {
  InstitutionNotSupportedException({
    super.message = 'Your college email domain is not currently supported on WarmPath.',
    super.details,
  }) : super(code: 'institution_not_supported', statusCode: 422);
}

class UnauthorizedException extends AppException {
  UnauthorizedException({
    super.message = 'Session expired or unauthenticated. Please log in again.',
    super.details,
  }) : super(code: 'unauthorized', statusCode: 401);
}

class ForbiddenException extends AppException {
  ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.details,
  }) : super(code: 'forbidden', statusCode: 403);
}

class NotFoundException extends AppException {
  NotFoundException({
    super.message = 'The requested resource was not found.',
    super.details,
  }) : super(code: 'not_found', statusCode: 404);
}

class ValidationException extends AppException {
  ValidationException({
    super.message = 'Validation failed for request data.',
    super.details,
  }) : super(code: 'validation_error', statusCode: 422);
}

class RateLimitException extends AppException {
  RateLimitException({
    super.message = 'Rate limit exceeded. Please wait a moment before trying again.',
    super.details,
  }) : super(code: 'rate_limit_exceeded', statusCode: 429);
}

class NetworkException extends AppException {
  NetworkException({
    super.message = 'Network connection failed. Please check your connectivity.',
    super.details,
  }) : super(code: 'network_error', statusCode: 0);
}

class ServerException extends AppException {
  ServerException({
    super.message = 'Internal server error occurred. Please try again later.',
    super.details,
  }) : super(code: 'server_error', statusCode: 500);
}
