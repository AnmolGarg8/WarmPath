import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warmpath_app/app_router.dart';
import 'package:warmpath_app/core/api/dio_client.dart';
import 'package:warmpath_app/core/storage/secure_storage.dart';
import 'package:warmpath_app/features/auth/auth_providers.dart';
import 'package:warmpath_app/features/auth/auth_repository.dart';
import 'package:warmpath_app/main.dart';

class FakeAuthRepository extends AuthRepository {
  final Map<String, dynamic> userToReturn;

  FakeAuthRepository({required this.userToReturn});

  @override
  Future<void> requestOtp(String email) async {}

  @override
  Future<Map<String, dynamic>> verifyOtp(String email, String code) async {
    await SecureStorageService.saveTokens(
      accessToken: 'fake_access_token',
      refreshToken: 'fake_refresh_token',
    );
    await SecureStorageService.saveUser(userToReturn);
    return {
      'access_token': 'fake_access_token',
      'refresh_token': 'fake_refresh_token',
      'is_new': false,
      'user': userToReturn,
    };
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    return userToReturn;
  }

  @override
  Future<void> logout() async {
    await SecureStorageService.clearAll();
  }

  @override
  Future<void> deleteAccount() async {
    await SecureStorageService.clearAll();
  }

  @override
  Future<Map<String, dynamic>> exportData() async {
    return {'data': 'test_export'};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = {
    'id': '11111111-1111-1111-1111-111111111111',
    'email': 'student@vips.edu',
    'full_name': 'Anmol Garg',
    'display_name': 'Anmol Garg',
    'headline': 'B.Tech CSE • Batch 2026',
    'badges': ['Student', 'Alumnus'],
    'trust_level': 'verified',
  };

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SecureStorageService.clearAll();
    AuthNotifierBridge.instance.setAuthenticated(false);
  });

  group('Auth Gating and Router Protection Tests', () {
    testWidgets('Cold start of app when signed out lands on splash -> email; cannot navigate to shell tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository(userToReturn: testUser)),
          ],
          child: const WarmPathApp(),
        ),
      );
      await tester.pump();
      expect(find.text('WarmPath'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Lands on /auth/email
      expect(find.text('Enter Campus Email'), findsOneWidget);

      // Attempt navigation to shell tabs - must be redirected to /auth/email
      appRouter.go('/discover');
      await tester.pumpAndSettle();
      expect(find.text('Enter Campus Email'), findsOneWidget);

      appRouter.go('/sessions');
      await tester.pumpAndSettle();
      expect(find.text('Enter Campus Email'), findsOneWidget);

      appRouter.go('/inbox');
      await tester.pumpAndSettle();
      expect(find.text('Enter Campus Email'), findsOneWidget);

      appRouter.go('/plans-wallet');
      await tester.pumpAndSettle();
      expect(find.text('Enter Campus Email'), findsOneWidget);

      appRouter.go('/profile');
      await tester.pumpAndSettle();
      expect(find.text('Enter Campus Email'), findsOneWidget);
    });

    testWidgets('Sign in with OTP lands on /discover; Profile tab shows user name and badges', (tester) async {
      await SecureStorageService.saveTokens(
        accessToken: 'authenticated_access_token',
        refreshToken: 'authenticated_refresh_token',
      );
      await SecureStorageService.saveUser(testUser);
      AuthNotifierBridge.instance.setAuthenticated(true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository(userToReturn: testUser)),
          ],
          child: const WarmPathApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Lands on Discover
      expect(find.text('WarmPath Recommendations'), findsOneWidget);

      // Navigate to Profile tab
      appRouter.go('/profile');
      await tester.pumpAndSettle();

      // Profile tab shows user details and verified badges
      expect(find.text('Anmol Garg'), findsOneWidget);
      expect(find.text('student@vips.edu'), findsOneWidget);
      expect(find.text('B.Tech CSE • Batch 2026'), findsOneWidget);
      expect(find.text('Verified Student'), findsOneWidget);
      expect(find.text('Verified Alumnus'), findsOneWidget);
      expect(find.text('Download My Data (DPDP Export)'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);

      // "Sign In / Register" card must NOT be present on Profile tab
      expect(find.text('Sign In to WarmPath'), findsNothing);
      expect(find.text('Sign In / Register'), findsNothing);
    });

    testWidgets('Logout returns to /auth/email and subsequent launch remains on /auth/email', (tester) async {
      await SecureStorageService.saveTokens(
        accessToken: 'authenticated_access_token',
        refreshToken: 'authenticated_refresh_token',
      );
      await SecureStorageService.saveUser(testUser);
      AuthNotifierBridge.instance.setAuthenticated(true);

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository(userToReturn: testUser)),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              capturedRef = ref;
              return const WarmPathApp();
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Navigate to profile
      appRouter.go('/profile');
      await tester.pumpAndSettle();
      expect(find.text('Anmol Garg'), findsOneWidget);

      // Perform logout
      await capturedRef.read(authStateProvider.notifier).logout();
      appRouter.go('/auth/email');
      await tester.pumpAndSettle();

      // Must land on /auth/email
      expect(find.text('Enter Campus Email'), findsOneWidget);
      expect(await SecureStorageService.getAccessToken(), isNull);
      expect(await SecureStorageService.getRefreshToken(), isNull);

      // Subsequent cold start
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository(userToReturn: testUser)),
          ],
          child: const WarmPathApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Enter Campus Email'), findsOneWidget);
    });

    testWidgets('401 unrecoverable refresh failure triggers onLogout callback and resets router to /auth/email', (tester) async {
      await SecureStorageService.saveTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'bad_refresh_token',
      );
      AuthNotifierBridge.instance.setAuthenticated(true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository(userToReturn: testUser)),
          ],
          child: const WarmPathApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Trigger onLogout callback as DioClient does on 401 failure (after clearing storage)
      await SecureStorageService.clearAll();
      DioClient().onLogout?.call();
      await tester.pumpAndSettle();

      expect(find.text('Enter Campus Email'), findsOneWidget);
      expect(AuthNotifierBridge.instance.isAuthenticated, isFalse);
    });
  });
}
