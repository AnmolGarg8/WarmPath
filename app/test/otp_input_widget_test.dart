import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/auth/pages/otp_page.dart';

void main() {
  testWidgets('OtpPage renders 6 input boxes and email header', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OtpPage(email: 'student@vips.edu'),
        ),
      ),
    );

    expect(find.text('Enter Verification Code'), findsOneWidget);
    expect(find.textContaining('student@vips.edu'), findsOneWidget);

    // Verify 6 OTP text fields exist
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(6));

    // Verify 'Verify & Continue' button exists
    expect(find.text('Verify & Continue'), findsOneWidget);
  });

  testWidgets('OtpPage displays validation error when submitting incomplete code',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OtpPage(email: 'student@vips.edu'),
        ),
      ),
    );

    // Tap verify without entering code
    final verifyButton = find.text('Verify & Continue');
    await tester.tap(verifyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter all 6 digits of the code.'), findsOneWidget);
  });

  testWidgets('Entering digits populates the OTP input boxes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OtpPage(email: 'student@vips.edu'),
        ),
      ),
    );

    final firstBox = find.byType(TextField).first;
    await tester.enterText(firstBox, '1');
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}
