// allow-mock-file: guided demo, simulated and labelled
import '../data/personas.dart';
import 'contracts.dart';
import 'demo_config.dart';

class SessionEngineImpl implements SessionEngine {
  @override
  DemoSession createInstantRequest(SamplePersona giver, double creditValue) {
    if (giver.remainingCapacity <= 0) {
      throw StateError('Cannot request session: Giver has reached weekly capacity.');
    }

    return DemoSession(
      id: 'demo_sess_${DateTime.now().millisecondsSinceEpoch}',
      student: DemoPersonas.studentRiya,
      giver: giver,
      state: SessionState.scheduled,
      scheduledAt: DateTime.now(),
      durationMinutes: 20,
      studentJoinedMinutes: 0,
      giverJoinedMinutes: 0,
      creditValue: creditValue,
      isCreditReserved: true, // Escrow credit reserved immediately
    );
  }

  @override
  DemoSession acceptRequest(DemoSession session) {
    if (session.giver.remainingCapacity <= 0) {
      throw StateError('Giver is currently at capacity for this week.');
    }
    return session.copyWith(state: SessionState.scheduled);
  }

  @override
  SessionCompletionResult verifyCompletion({
    required int studentJoinedMin,
    required int giverJoinedMin,
  }) {
    final int overlap = studentJoinedMin < giverJoinedMin ? studentJoinedMin : giverJoinedMin;

    if (studentJoinedMin == 0 || giverJoinedMin == 0) {
      return SessionCompletionResult(
        isCompleted: false,
        overlapMinutes: 0,
        statusDescription: giverJoinedMin == 0
            ? 'Giver No-Show: Giver failed to join call. Automatic 100% credit refund triggered.'
            : 'Student No-Show: Student did not join call.',
      );
    }

    if (overlap < DemoConfig.minimumCallOverlapMinutes) {
      return SessionCompletionResult(
        isCompleted: false,
        overlapMinutes: overlap,
        statusDescription:
            'Incomplete: Call overlap was $overlap mins (minimum ${DemoConfig.minimumCallOverlapMinutes} mins required). Credit refunded.',
      );
    }

    return SessionCompletionResult(
      isCompleted: true,
      overlapMinutes: overlap,
      statusDescription:
          'Verified Complete: Both parties met for $overlap minutes (exceeds ${DemoConfig.minimumCallOverlapMinutes}-minute threshold). Escrow entered 48-hour dispute window.',
    );
  }

  @override
  DemoSession transitionState(DemoSession session, SessionState newState) {
    bool reserved = session.isCreditReserved;
    if (newState == SessionState.refunded || newState == SessionState.settled) {
      reserved = false;
    }
    return session.copyWith(state: newState, isCreditReserved: reserved);
  }
}
