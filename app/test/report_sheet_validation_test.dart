import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/safety/widgets/report_sheet.dart';

void main() {
  testWidgets('ReportSheet renders options and validates mandatory reason selection',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReportSheet(
              targetUserId: 'user-123',
              targetName: 'Suspicious Member',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Report Suspicious Member'), findsOneWidget);
    expect(find.text('Select Reason *'), findsOneWidget);
    expect(find.text('Asking for money / fees / deposit'), findsOneWidget);
    expect(find.text('Pushing to WhatsApp / Telegram'), findsOneWidget);

    // Tap submit without selecting reason
    final submitButton = find.text('Submit Confidential Report');
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('Please select a reason for this report.'), findsOneWidget);

    // Now select a reason
    final scamOption = find.text('Asking for money / fees / deposit');
    await tester.tap(scamOption);
    await tester.pump();

    // Verify error disappears
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  });
}
