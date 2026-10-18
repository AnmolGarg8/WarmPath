import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/demo/chapters/registry.dart';
import 'package:warmpath_app/features/demo/data/personas.dart';
import 'package:warmpath_app/features/demo/engine/contracts.dart';
import 'package:warmpath_app/features/demo/engine/demo_config.dart';
import 'package:warmpath_app/features/demo/models/demo_models.dart';
import 'package:warmpath_app/features/demo/state/demo_state.dart';

void main() {
  group('DemoController State & Navigation Tests', () {
    late DemoController controller;

    setUp(() {
      controller = DemoController();
    });

    test('Initial state starts at Chapter 0, Step 0 with Student perspective', () {
      final state = controller.debugState;
      expect(state.chapterIndex, 0);
      expect(state.stepIndex, 0);
      expect(state.selectedActor, DemoActor.student);
      expect(state.eventLog.events, isNotEmpty);
    });

    test('nextStep advances step and moves to next chapter when step boundary reached', () {
      final initialChapterSteps = demoChaptersRegistry[0].steps.length;

      // Advance through chapter 0
      for (int i = 0; i < initialChapterSteps - 1; i++) {
        controller.nextStep();
      }
      expect(controller.debugState.chapterIndex, 0);
      expect(controller.debugState.stepIndex, initialChapterSteps - 1);

      // Next step should transition to Chapter 1, Step 0
      controller.nextStep();
      expect(controller.debugState.chapterIndex, 1);
      expect(controller.debugState.stepIndex, 0);
    });

    test('previousStep moves backward cleanly', () {
      controller.jumpToChapter(1);
      expect(controller.debugState.chapterIndex, 1);
      expect(controller.debugState.stepIndex, 0);

      controller.previousStep();
      expect(controller.debugState.chapterIndex, 0);
      expect(controller.debugState.stepIndex, demoChaptersRegistry[0].steps.length - 1);
    });

    test('fastForward48Hours advances clock and settles dispute window for active session', () {
      // Start instant session
      controller.purchasePlan(DemoConfig.highPlan);
      controller.startInstantSession(DemoPersonas.giverArjun);
      controller.completeActiveSession(studentJoinedMin: 18, giverJoinedMin: 18);

      expect(controller.debugState.activeSession?.state, SessionState.disputeWindow);

      // Fast forward 48 hours
      controller.fastForward48Hours();

      expect(controller.debugState.activeSession?.state, SessionState.settled);
      expect(controller.debugState.fastForwarded, isTrue);
    });

    test('reset clears event log and returns to initial chapter', () {
      controller.nextStep();
      controller.nextStep();
      controller.purchasePlan(DemoConfig.premiumPlan);

      expect(controller.debugState.eventLog.events.length, greaterThan(1));

      controller.reset();

      expect(controller.debugState.chapterIndex, 0);
      expect(controller.debugState.stepIndex, 0);
      expect(controller.debugState.selectedPlan.id, DemoConfig.campusPlan.id);
    });

    test('Interactive filters: add/remove skills, toggle gates, switch actors', () {
      controller.addSkill('Docker');
      expect(controller.debugState.currentSkills.contains('Docker'), isTrue);

      controller.removeSkill('Docker');
      expect(controller.debugState.currentSkills.contains('Docker'), isFalse);

      final initialGate = controller.debugState.capacityGateEnabled;
      controller.toggleCapacityGate();
      expect(controller.debugState.capacityGateEnabled, !initialGate);

      controller.setActor(DemoActor.moderator);
      expect(controller.debugState.selectedActor, DemoActor.moderator);
    });
  });
}
