import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/core/api/dio_client.dart';
import 'package:warmpath_app/features/onboarding/onboarding_models.dart';
import 'package:warmpath_app/features/onboarding/onboarding_page.dart';
import 'package:warmpath_app/features/onboarding/onboarding_providers.dart';

void main() {
  group('OnboardingPage Widget Tests', () {
    testWidgets('assert empty response displays the empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeProfileProvider.overrideWith(
              (ref) => Future.value(const ResumeProfile(skills: [])),
            ),
            studentIntentProvider.overrideWith(
              (ref) => Future.value(const StudentIntent(intent: '')),
            ),
          ],
          child: const MaterialApp(
            home: OnboardingPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Resume Uploaded'), findsOneWidget);
      expect(
        find.text('Upload your resume PDF to extract skills and state what you want next.'),
        findsOneWidget,
      );
      expect(find.text('Upload Resume PDF'), findsOneWidget);
    });

    testWidgets('assert 501 displays the not-available state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeProfileProvider.overrideWith(
              (ref) => Future.error(
                AppException(
                  code: 'module_not_implemented',
                  message: 'Endpoint is scaffolded and pending module implementation.',
                  statusCode: 501,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: OnboardingPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Feature Unavailable'), findsOneWidget);
      expect(find.text('This feature is not available yet'), findsOneWidget);
    });

    testWidgets('assert real-shaped response renders fields from response', (WidgetTester tester) async {
      final mockProfile = const ResumeProfile(
        id: 'profile-1',
        skills: [
          ResumeSkill(name: 'Python', category: 'languages'),
          ResumeSkill(name: 'Flutter', category: 'frameworks'),
          ResumeSkill(name: 'PostgreSQL', category: 'databases'),
        ],
      );
      final mockIntent = const StudentIntent(
        intent: 'Looking for mock interviews and system design feedback.',
        targetRoles: ['SDE-1', 'Backend Engineer'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeProfileProvider.overrideWith((ref) => Future.value(mockProfile)),
            studentIntentProvider.overrideWith((ref) => Future.value(mockIntent)),
          ],
          child: const MaterialApp(
            home: OnboardingPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Parsed Skills'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('PostgreSQL'), findsOneWidget);
      expect(find.text('What do you want next?'), findsOneWidget);
      expect(
        find.text('Looking for mock interviews and system design feedback.'),
        findsOneWidget,
      );
      expect(find.text('Save Intent'), findsOneWidget);
    });
  });
}
