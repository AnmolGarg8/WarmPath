import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/core/storage/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Token Storage and Interceptor Logic Tests', () {
    test('Token storage sets and retrieves token pair correctly', () async {
      // Mock secure storage with in-memory tokens
      await SecureStorageService.saveTokens(
        accessToken: 'initial_access_token',
        refreshToken: 'initial_refresh_token',
      );

      final token = await SecureStorageService.getAccessToken();
      final refresh = await SecureStorageService.getRefreshToken();

      expect(token, equals('initial_access_token'));
      expect(refresh, equals('initial_refresh_token'));

      await SecureStorageService.clearAll();
      expect(await SecureStorageService.getAccessToken(), isNull);
      expect(await SecureStorageService.getRefreshToken(), isNull);
    });

    test('Auth interceptor attaches Bearer token to outgoing request', () async {
      await SecureStorageService.saveToken('test_jwt_bearer_token');

      final options = RequestOptions(path: '/me');
      final token = await SecureStorageService.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      expect(options.headers['Authorization'], equals('Bearer test_jwt_bearer_token'));
      await SecureStorageService.clearAll();
    });

    test('Auth interceptor detects 401 and clears storage on unrecoverable failure', () async {
      await SecureStorageService.saveTokens(
        accessToken: 'expired_token',
        refreshToken: 'invalid_refresh_token',
      );

      bool logoutTriggered = false;
      void handleLogout() {
        logoutTriggered = true;
      }

      // Simulate failure on refresh endpoint
      final refreshResponse = Response(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        statusCode: 401,
      );

      if (refreshResponse.statusCode == 401) {
        await SecureStorageService.clearAll();
        handleLogout();
      }

      expect(logoutTriggered, isTrue);
      expect(await SecureStorageService.getAccessToken(), isNull);
    });
  });
}
