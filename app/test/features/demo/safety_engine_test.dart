import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/demo/engine/contracts.dart';
import 'package:warmpath_app/features/demo/engine/safety_engine_impl.dart';

void main() {
  group('SafetyEngine Table Tests (Pillar 4)', () {
    final engine = SafetyEngineImpl();

    test('Benign messages are allowed with no triggers', () {
      final benignCases = [
        'Could you review my resume?',
        'Hi Arjun, looking for guidance on backend engineering.',
        'Thanks for taking the time to meet today.',
        'What projects helped you the most during college?',
      ];

      for (final text in benignCases) {
        final res = engine.scanMessage(text);
        expect(res.action, SafetyAction.allow, reason: 'Failed on benign message: "$text"');
        expect(res.triggeredRules, isEmpty);
      }
    });

    test('Fee and off-platform payment attempts are blocked', () {
      final blockCases = [
        'Please pay me 500 advance for resume editing',
        'Send registration fees via GPay',
        'Transfer the money to my upi id',
        'Charges are 200 rs per session',
        'Deposit advance in my cash account',
      ];

      for (final text in blockCases) {
        final res = engine.scanMessage(text);
        expect(res.action, SafetyAction.block, reason: 'Should block payment scam: "$text"');
        expect(res.triggeredRules, isNotEmpty);
      }
    });

    test('Off-platform push channels are flagged for review', () {
      final reviewCases = [
        'Message me on whatsapp for faster reply',
        'Add me on telegram @mentor',
        'DM me on instagram to talk',
        'Let us talk outside the app',
      ];

      for (final text in reviewCases) {
        final res = engine.scanMessage(text);
        expect(
          res.action == SafetyAction.review || res.action == SafetyAction.block,
          isTrue,
          reason: 'Should flag off-platform push: "$text"',
        );
      }
    });

    test('Obfuscated phrases are normalized and caught', () {
      final obfuscatedCases = [
        'w h a t s a p p me here',
        'w.h.a.t.s.a.p.p for notes',
        'send m0ney to my account',
        'p@y me now',
      ];

      for (final text in obfuscatedCases) {
        final res = engine.scanMessage(text);
        expect(
          res.action != SafetyAction.allow,
          isTrue,
          reason: 'Should catch obfuscated bypass: "$text"',
        );
      }
    });

    test('Shortened URLs and link shorteners are flagged', () {
      final shortlinks = [
        'Check my calendar at bit.ly/mentor-slot',
        'Register here: tinyurl.com/free-session',
        'Join group: t.me/campus_group',
      ];

      for (final text in shortlinks) {
        final res = engine.scanMessage(text);
        expect(
          res.action == SafetyAction.review || res.action == SafetyAction.block,
          isTrue,
          reason: 'Should flag suspicious shortlink: "$text"',
        );
      }
    });

    test('Contact masking redacts phone numbers and emails', () {
      const input = 'Call +91 9876543210 or email riya@sample.edu for details';
      final masked = engine.maskContactInfo(input);

      expect(masked.contains('9876543210'), isFalse);
      expect(masked.contains('riya@sample.edu'), isFalse);
      expect(masked.contains('[PHONE MASKED FOR PRIVACY]'), isTrue);
      expect(masked.contains('[EMAIL MASKED FOR PRIVACY]'), isTrue);
    });

    test('Email verification approves valid campus domains and restricts external', () {
      final approved = engine.verifyEmail('student@demouniversity.edu');
      expect(approved.isApproved, isTrue);
      expect(approved.badge, contains('Verified'));

      final unapproved = engine.verifyEmail('external.guest@gmail.com');
      expect(unapproved.isApproved, isFalse);
      expect(unapproved.privileges, contains('Restricted'));
    });

    test('Graduated privileges enforces daily request limits', () {
      // New user: limit 1
      final res1 = engine.checkDailyLimits('new', 0);
      expect(res1.allowed, isTrue);
      expect(res1.remainingToday, 1);

      final res2 = engine.checkDailyLimits('new', 1);
      expect(res2.allowed, isFalse);
      expect(res2.reason, contains('Blocked'));

      // Verified user: limit 5
      final res3 = engine.checkDailyLimits('verified', 4);
      expect(res3.allowed, isTrue);
      expect(res3.remainingToday, 1);

      final res4 = engine.checkDailyLimits('verified', 5);
      expect(res4.allowed, isFalse);
    });
  });
}
