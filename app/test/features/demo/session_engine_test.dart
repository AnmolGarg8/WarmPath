import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/demo/data/personas.dart';
import 'package:warmpath_app/features/demo/engine/contracts.dart';
import 'package:warmpath_app/features/demo/engine/session_engine_impl.dart';

void main() {
  group('SessionEngine Tests (Pillar 5)', () {
    final engine = SessionEngineImpl();

    test('Completion matrix: both joined for >= 5 min passes verification', () {
      final res = engine.verifyCompletion(
        studentJoinedMin: 18,
        giverJoinedMin: 15,
      );

      expect(res.isCompleted, isTrue);
      expect(res.overlapMinutes, 15);
      expect(res.statusDescription, contains('Verified Complete'));
    });

    test('Completion matrix: overlap < 5 min fails completion', () {
      final res = engine.verifyCompletion(
        studentJoinedMin: 3,
        giverJoinedMin: 4,
      );

      expect(res.isCompleted, isFalse);
      expect(res.overlapMinutes, 3);
      expect(res.statusDescription, contains('Incomplete'));
    });

    test('Completion matrix: giver no-show triggers automatic refund notification', () {
      final res = engine.verifyCompletion(
        studentJoinedMin: 10,
        giverJoinedMin: 0, // Giver absent
      );

      expect(res.isCompleted, isFalse);
      expect(res.statusDescription, contains('Giver No-Show'));
    });

    test('Refuses to create request if giver has 0 weekly capacity', () {
      expect(
        () => engine.createInstantRequest(DemoPersonas.giverSanjayZeroCapacity, 250.0),
        throwsA(isA<StateError>()),
      );
    });

    test('Lifecycle transitions update session states correctly', () {
      final sess = engine.createInstantRequest(DemoPersonas.giverArjun, 0.0);
      expect(sess.state, SessionState.scheduled);
      expect(sess.isCreditReserved, isTrue);

      final inProg = engine.transitionState(sess, SessionState.inProgress);
      expect(inProg.state, SessionState.inProgress);

      final settled = engine.transitionState(inProg, SessionState.settled);
      expect(settled.state, SessionState.settled);
      expect(settled.isCreditReserved, isFalse);
    });
  });
}
