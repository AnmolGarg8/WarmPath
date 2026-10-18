import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warmpath_app/app_router.dart';
import 'package:warmpath_app/core/storage/secure_storage.dart';
import 'package:warmpath_app/features/auth/auth_providers.dart';
import 'package:warmpath_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SecureStorageService.clearAll();
    AuthNotifierBridge.instance.setAuthenticated(false);
  });

  testWidgets('WarmPathApp cold start when signed out lands on splash -> email', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WarmPathApp()));
    await tester.pump();
    // Splash page is visible during initial boot
    expect(find.text('WarmPath'), findsOneWidget);

    // Settle through the 300ms delay to email page
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Enter Campus Email'), findsOneWidget);
    expect(find.text('WarmPath Recommendations'), findsNothing);
  });

  testWidgets('Signed-out user cannot navigate to /discover or /profile', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WarmPathApp()));
    await tester.pumpAndSettle();

    // Attempt direct navigation to private route /discover
    appRouter.go('/discover');
    await tester.pumpAndSettle();

    // Must be blocked and redirected to /auth/email
    expect(find.text('Enter Campus Email'), findsOneWidget);
    expect(find.text('WarmPath Recommendations'), findsNothing);

    // Attempt direct navigation to private route /profile
    appRouter.go('/profile');
    await tester.pumpAndSettle();

    expect(find.text('Enter Campus Email'), findsOneWidget);
  });

  testWidgets('WarmPathApp lands on Discover when authenticated', (WidgetTester tester) async {
    await SecureStorageService.saveTokens(
      accessToken: 'valid_test_access_token',
      refreshToken: 'valid_test_refresh_token',
    );
    await SecureStorageService.saveUser({
      'id': '00000000-0000-0000-0000-000000000001',
      'email': 'student@vips.edu',
      'full_name': 'Test Student',
      'display_name': 'Test Student',
      'badges': ['Verified Student'],
    });
    AuthNotifierBridge.instance.setAuthenticated(true);

    await tester.pumpWidget(const ProviderScope(child: WarmPathApp()));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('WarmPath Recommendations'), findsOneWidget);
  });
}
