import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/demo/engine/institution_engine_impl.dart';
import 'package:warmpath_app/features/demo/models/demo_event_log.dart';

void main() {
  group('InstitutionEngine Tests (Pillar 6)', () {
    final engine = InstitutionEngineImpl();

    test('Computes baseline metrics from empty event log', () {
      final log = DemoEventLog();
      final metrics = engine.computeMetrics(log);

      expect(metrics.requestsPosted, 42);
      expect(metrics.sessionsCompleted, 35);
      expect(metrics.scamsBlockedCount, 4);
      expect(metrics.avgResolutionHours, 2.4);
      expect(metrics.skillGaps, isNotEmpty);
    });

    test('Dynamically folds in demo events from DemoEventLog', () {
      final log = DemoEventLog();

      log.log(
        type: 'RequestCreated',
        actor: 'Student',
        description: 'New session request',
        virtualTime: 'Day 1, 10:00 AM',
      );
      log.log(
        type: 'SessionCompleted',
        actor: 'Session Engine',
        description: 'Session finished',
        virtualTime: 'Day 1, 10:30 AM',
        payload: {'isOwnCollege': true},
      );
      log.log(
        type: 'ScamBlocked',
        actor: 'Safety Engine',
        description: 'Payment bypass prevented',
        virtualTime: 'Day 1, 11:00 AM',
      );

      final metrics = engine.computeMetrics(log);

      // Baseline 42 + 1 = 43
      expect(metrics.requestsPosted, 43);
      // Baseline 35 + 1 = 36
      expect(metrics.sessionsCompleted, 36);
      // Baseline 4 + 1 = 5
      expect(metrics.scamsBlockedCount, 5);
    });

    test('Skill gap analysis detects high-demand low-supply fields', () {
      final log = DemoEventLog();
      final metrics = engine.computeMetrics(log);

      // Cloud Architecture has high demand and low alumni supply in baseline
      expect(
        metrics.skillGaps.any((gap) => gap.contains('Cloud Architecture') || gap.contains('Kubernetes')),
        isTrue,
      );
    });
  });
}
