import 'package:flutter_test/flutter_test.dart';
import 'sessions_error_helper.dart';

void main() {
  group('Credit Disclosure Tests', () {
    test('discloses 0 credits for own college', () {
      final text = getCreditDisclosureText(isOwnCollege: true, planName: 'Campus');
      expect(text, contains('Free: own college network'));
      expect(text, contains('0 credits'));
    });

    test('discloses paid credit for cross college', () {
      final text = getCreditDisclosureText(isOwnCollege: false, planName: 'Standard', cost: 1);
      expect(text, contains('uses 1 credit'));
      expect(text, contains('Standard'));
    });
  });

  group('Session Error Translation Tests', () {
    test('translates known typed errors into clear human messages', () {
      expect(
        translateSessionError('giver_at_capacity'),
        contains('reached their weekly session limit'),
      );
      expect(
        translateSessionError('slot_already_booked'),
        contains('already been taken'),
      );
      expect(
        translateSessionError('plan_access_denied'),
        contains('does not grant cross-college access'),
      );
      expect(
        translateSessionError('intent_blocked'),
        contains('flagged by trust & safety filters'),
      );
    });

    test('falls back on unknown code', () {
      expect(translateSessionError('custom_error', 'Fallback error message'), 'Fallback error message');
    });
  });
}
