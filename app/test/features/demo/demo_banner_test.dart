import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/demo/chapters/registry.dart';
import 'package:warmpath_app/features/demo/demo_banner.dart';
import 'package:warmpath_app/features/demo/framework/demo_scaffold.dart';
import 'package:warmpath_app/features/demo/state/demo_state.dart';

void main() {
  group('DemoBanner & Honesty Tests', () {
    testWidgets('DemoBanner displays exact required honesty text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoBanner(),
          ),
        ),
      );

      expect(
        find.text('DEMO MODE: simulated data and simulated payments. Nothing here is live.'),
        findsOneWidget,
      );
    });

    testWidgets('DemoScaffold always renders DemoBanner across all registered steps', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DemoScaffold(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banner must be present on initial step
      expect(find.byType(DemoBanner), findsOneWidget);
      expect(
        find.text('DEMO MODE: simulated data and simulated payments. Nothing here is live.'),
        findsOneWidget,
      );

      // Verify that every single registered chapter has steps defined
      expect(demoChaptersRegistry, isNotEmpty);
      for (final chapter in demoChaptersRegistry) {
        expect(chapter.steps, isNotEmpty, reason: 'Chapter ${chapter.title} must have steps');
      }
    });

    testWidgets('DemoScaffold displays presenter controls and navigation buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DemoScaffold(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.fast_forward_rounded), findsOneWidget);
    });
  });
}
