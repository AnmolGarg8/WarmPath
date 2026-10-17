import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/core/api/public_config.dart';
import 'package:warmpath_app/core/widgets/demo_banner.dart';

void main() {
  group('DemoBanner and TestModeBanner Widget Tests', () {
    testWidgets('DemoBanner renders text when demoProfile is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            publicConfigProvider.overrideWith(
              (ref) => Future.value(
                const PublicConfig(
                  demoProfile: true,
                  testMode: true,
                  disputeMinutes: 2,
                  noReplyMinutes: 5,
                  minCallSeconds: 60,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  DemoBanner(),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Demo profile: timers are shortened for the demo'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('DemoBanner renders nothing when demoProfile is false (production)', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            publicConfigProvider.overrideWith(
              (ref) => Future.value(
                const PublicConfig(
                  demoProfile: false,
                  testMode: false,
                  disputeMinutes: 2880,
                  noReplyMinutes: 4320,
                  minCallSeconds: 300,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  DemoBanner(),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Demo profile: timers are shortened for the demo'), findsNothing);
      expect(find.byIcon(Icons.timer_outlined), findsNothing);
    });

    testWidgets('TestModeBanner renders when testMode is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            publicConfigProvider.overrideWith(
              (ref) => Future.value(
                const PublicConfig(
                  demoProfile: true,
                  testMode: true,
                  disputeMinutes: 2,
                  noReplyMinutes: 5,
                  minCallSeconds: 60,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TestModeBanner(),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test mode: no real money moves'), findsOneWidget);
    });

    testWidgets('BandThresholdNotice renders when band thresholds are lowered', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            publicConfigProvider.overrideWith(
              (ref) => Future.value(
                const PublicConfig(
                  demoProfile: true,
                  testMode: true,
                  disputeMinutes: 2,
                  noReplyMinutes: 5,
                  minCallSeconds: 60,
                  loweredBandThresholds: true,
                  trustedMinSessions: 1,
                  topRatedMinSessions: 2,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  BandThresholdNotice(),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Demo profile: band thresholds are shortened for demonstration '
          '(Trusted: 1 session, Top Rated: 2 sessions).',
        ),
        findsOneWidget,
      );
    });
  });
}
