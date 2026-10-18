// allow-mock-file: guided demo, simulated and labelled
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chapters/registry.dart';
import '../data/personas.dart';
import '../engine/contracts.dart';
import '../engine/demo_config.dart';
import '../engine/institution_engine_impl.dart';
import '../engine/ledger_engine_impl.dart';
import '../engine/matching_engine_impl.dart';
import '../engine/rating_engine_impl.dart';
import '../engine/safety_engine_impl.dart';
import '../engine/session_engine_impl.dart';
import '../models/demo_event_log.dart';
import '../models/demo_models.dart';

class DemoState {
  final int chapterIndex;
  final int stepIndex;
  final DemoActor selectedActor;
  final VirtualClock virtualClock;
  final DemoEventLog eventLog;
  final bool showPresenterNotes;
  final bool autoPlay;
  final bool fastForwarded;

  // Interactive Engines
  final SafetyEngineImpl safetyEngine;
  final MatchingEngineImpl matchingEngine;
  final RatingEngineImpl ratingEngine;
  final SessionEngineImpl sessionEngine;
  final LedgerEngineImpl ledgerEngine;
  final InstitutionEngineImpl institutionEngine;

  // Interactive Chapter State
  final String currentIntent;
  final List<String> currentSkills;
  final bool capacityGateEnabled;
  final bool safetyGateEnabled;
  final DemoPlan selectedPlan;
  final DemoSession? activeSession;
  final double latestSmoothedRating;
  final GiverBand latestBand;

  DemoState({
    required this.chapterIndex,
    required this.stepIndex,
    required this.selectedActor,
    required this.virtualClock,
    required this.eventLog,
    this.showPresenterNotes = true,
    this.autoPlay = false,
    this.fastForwarded = false,
    required this.safetyEngine,
    required this.matchingEngine,
    required this.ratingEngine,
    required this.sessionEngine,
    required this.ledgerEngine,
    required this.institutionEngine,
    required this.currentIntent,
    required this.currentSkills,
    this.capacityGateEnabled = true,
    this.safetyGateEnabled = true,
    required this.selectedPlan,
    this.activeSession,
    this.latestSmoothedRating = 4.6,
    this.latestBand = GiverBand.rising,
  });

  DemoChapter get currentChapter => demoChaptersRegistry[chapterIndex];
  DemoStep get currentStep => currentChapter.steps[stepIndex];

  DemoState copyWith({
    int? chapterIndex,
    int? stepIndex,
    DemoActor? selectedActor,
    VirtualClock? virtualClock,
    DemoEventLog? eventLog,
    bool? showPresenterNotes,
    bool? autoPlay,
    bool? fastForwarded,
    String? currentIntent,
    List<String>? currentSkills,
    bool? capacityGateEnabled,
    bool? safetyGateEnabled,
    DemoPlan? selectedPlan,
    DemoSession? activeSession,
    double? latestSmoothedRating,
    GiverBand? latestBand,
  }) {
    return DemoState(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      stepIndex: stepIndex ?? this.stepIndex,
      selectedActor: selectedActor ?? this.selectedActor,
      virtualClock: virtualClock ?? this.virtualClock,
      eventLog: eventLog ?? this.eventLog,
      showPresenterNotes: showPresenterNotes ?? this.showPresenterNotes,
      autoPlay: autoPlay ?? this.autoPlay,
      fastForwarded: fastForwarded ?? this.fastForwarded,
      safetyEngine: safetyEngine,
      matchingEngine: matchingEngine,
      ratingEngine: ratingEngine,
      sessionEngine: sessionEngine,
      ledgerEngine: ledgerEngine,
      institutionEngine: institutionEngine,
      currentIntent: currentIntent ?? this.currentIntent,
      currentSkills: currentSkills ?? this.currentSkills,
      capacityGateEnabled: capacityGateEnabled ?? this.capacityGateEnabled,
      safetyGateEnabled: safetyGateEnabled ?? this.safetyGateEnabled,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      activeSession: activeSession ?? this.activeSession,
      latestSmoothedRating: latestSmoothedRating ?? this.latestSmoothedRating,
      latestBand: latestBand ?? this.latestBand,
    );
  }
}

class DemoController extends StateNotifier<DemoState> {
  DemoController()
      : super(
          DemoState(
            chapterIndex: 0,
            stepIndex: 0,
            selectedActor: DemoActor.student,
            virtualClock: VirtualClock(),
            eventLog: DemoEventLog(),
            safetyEngine: SafetyEngineImpl(),
            matchingEngine: MatchingEngineImpl(),
            ratingEngine: RatingEngineImpl(),
            sessionEngine: SessionEngineImpl(),
            ledgerEngine: LedgerEngineImpl(),
            institutionEngine: InstitutionEngineImpl(),
            currentIntent: 'Looking for summer backend engineering guidance & resume review',
            currentSkills: ['Python', 'SQL', 'FastAPI', 'Machine Learning'],
            selectedPlan: DemoConfig.campusPlan,
          ),
        ) {
    _triggerOnEnter();
  }

  void _triggerOnEnter() {
    final step = state.currentStep;
    step.onEnter?.call(state.eventLog, state.virtualClock);
    // Auto-sync actor to step's intended actor
    if (state.selectedActor != step.actor) {
      state = state.copyWith(selectedActor: step.actor);
    }
  }

  void nextStep() {
    final chapter = state.currentChapter;
    if (state.stepIndex < chapter.steps.length - 1) {
      state = state.copyWith(stepIndex: state.stepIndex + 1);
      state.virtualClock.advanceMinutes(15);
      _triggerOnEnter();
    } else if (state.chapterIndex < demoChaptersRegistry.length - 1) {
      state = state.copyWith(
        chapterIndex: state.chapterIndex + 1,
        stepIndex: 0,
      );
      state.virtualClock.advanceMinutes(30);
      _triggerOnEnter();
    }
  }

  void previousStep() {
    if (state.stepIndex > 0) {
      state = state.copyWith(stepIndex: state.stepIndex - 1);
      _triggerOnEnter();
    } else if (state.chapterIndex > 0) {
      final prevChapter = demoChaptersRegistry[state.chapterIndex - 1];
      state = state.copyWith(
        chapterIndex: state.chapterIndex - 1,
        stepIndex: prevChapter.steps.length - 1,
      );
      _triggerOnEnter();
    }
  }

  void jumpToChapter(int chIdx) {
    if (chIdx >= 0 && chIdx < demoChaptersRegistry.length) {
      state = state.copyWith(
        chapterIndex: chIdx,
        stepIndex: 0,
      );
      _triggerOnEnter();
    }
  }

  void jumpToStep(int chIdx, int stIdx) {
    if (chIdx >= 0 && chIdx < demoChaptersRegistry.length) {
      final ch = demoChaptersRegistry[chIdx];
      if (stIdx >= 0 && stIdx < ch.steps.length) {
        state = state.copyWith(
          chapterIndex: chIdx,
          stepIndex: stIdx,
        );
        _triggerOnEnter();
      }
    }
  }

  void setActor(DemoActor actor) {
    state = state.copyWith(selectedActor: actor);
  }

  void togglePresenterNotes() {
    state = state.copyWith(showPresenterNotes: !state.showPresenterNotes);
  }

  void toggleAutoPlay() {
    state = state.copyWith(autoPlay: !state.autoPlay);
  }

  void fastForward48Hours() {
    state.virtualClock.fastForwardHours(48);
    // If active session was in dispute window, settle it!
    if (state.activeSession != null &&
        (state.activeSession!.state == SessionState.disputeWindow ||
            state.activeSession!.state == SessionState.completed)) {
      state.ledgerEngine.settleCreditWithBandPayout(
        studentId: state.activeSession!.student.id,
        giverId: state.activeSession!.giver.id,
        creditValue: state.activeSession!.creditValue,
        band: state.activeSession!.giver.band,
      );

      final settled = state.sessionEngine.transitionState(
        state.activeSession!,
        SessionState.settled,
      );

      state.eventLog.log(
        type: 'CreditSettled',
        actor: 'Ledger Engine',
        description:
            '48h dispute window expired without disputes. Escrow released to ${state.activeSession!.giver.name} with ${state.activeSession!.giver.band} band payout.',
        virtualTime: state.virtualClock.format(),
        payload: {'giverId': state.activeSession!.giver.id, 'band': state.activeSession!.giver.band},
      );

      state = state.copyWith(activeSession: settled, fastForwarded: true);
    } else {
      state = state.copyWith(fastForwarded: true);
    }
  }

  void reset() {
    state.virtualClock.reset();
    state.eventLog.clear();
    state = DemoState(
      chapterIndex: 0,
      stepIndex: 0,
      selectedActor: DemoActor.student,
      virtualClock: state.virtualClock,
      eventLog: state.eventLog,
      safetyEngine: state.safetyEngine,
      matchingEngine: state.matchingEngine,
      ratingEngine: state.ratingEngine,
      sessionEngine: state.sessionEngine,
      ledgerEngine: LedgerEngineImpl(), // Fresh clean ledger
      institutionEngine: state.institutionEngine,
      currentIntent: 'Looking for summer backend engineering guidance & resume review',
      currentSkills: ['Python', 'SQL', 'FastAPI', 'Machine Learning'],
      selectedPlan: DemoConfig.campusPlan,
    );
    _triggerOnEnter();
  }

  void updateIntent(String newIntent) {
    state = state.copyWith(currentIntent: newIntent);
    state.eventLog.log(
      type: 'IntentSet',
      actor: 'Student',
      description: 'Student updated target intent: "$newIntent"',
      virtualTime: state.virtualClock.format(),
      payload: {'intent': newIntent},
    );
  }

  void addSkill(String skill) {
    if (!state.currentSkills.contains(skill)) {
      final updated = List<String>.from(state.currentSkills)..add(skill);
      state = state.copyWith(currentSkills: updated);
    }
  }

  void removeSkill(String skill) {
    final updated = List<String>.from(state.currentSkills)..remove(skill);
    state = state.copyWith(currentSkills: updated);
  }

  void toggleCapacityGate() {
    state = state.copyWith(capacityGateEnabled: !state.capacityGateEnabled);
  }

  void toggleSafetyGate() {
    state = state.copyWith(safetyGateEnabled: !state.safetyGateEnabled);
  }

  void purchasePlan(DemoPlan plan) {
    state.ledgerEngine.activatePurchasedPlan(
      studentId: DemoPersonas.studentRiya.id,
      plan: plan,
    );
    state.eventLog.log(
      type: 'PlanPurchased',
      actor: 'Student',
      description: 'Student subscribed to ${plan.name} Plan (Simulated payment: Rs ${plan.priceInr})',
      virtualTime: state.virtualClock.format(),
      payload: {'planId': plan.id, 'price': plan.priceInr},
    );
    state = state.copyWith(selectedPlan: plan);
  }

  void startInstantSession(SamplePersona giver) {
    final double creditVal = giver.isOwnCollege ? 0.0 : state.selectedPlan.creditUnitValueInr;
    final session = state.sessionEngine.createInstantRequest(giver, creditVal);

    if (giver.isOwnCollege) {
      state.ledgerEngine.recordCampusFreeSession(
        studentId: DemoPersonas.studentRiya.id,
        giverId: giver.id,
      );
    } else {
      state.ledgerEngine.reservePaidCredit(
        studentId: DemoPersonas.studentRiya.id,
        creditValue: creditVal,
        planId: state.selectedPlan.id,
      );
    }

    state.eventLog.log(
      type: 'RequestCreated',
      actor: 'Student',
      description: 'Instant connect request created with ${giver.name}',
      virtualTime: state.virtualClock.format(),
      payload: {'giverId': giver.id, 'isOwnCollege': giver.isOwnCollege},
    );

    state = state.copyWith(activeSession: session);
  }

  void completeActiveSession({required int studentJoinedMin, required int giverJoinedMin}) {
    if (state.activeSession == null) return;

    final verification = state.sessionEngine.verifyCompletion(
      studentJoinedMin: studentJoinedMin,
      giverJoinedMin: giverJoinedMin,
    );

    if (verification.isCompleted) {
      final completed = state.sessionEngine.transitionState(
        state.activeSession!,
        SessionState.disputeWindow,
      );
      state.eventLog.log(
        type: 'SessionCompleted',
        actor: 'Session Engine',
        description: 'Session verified complete (${verification.overlapMinutes}m overlap). 48h dispute window opened.',
        virtualTime: state.virtualClock.format(),
        payload: {
          'giverId': state.activeSession!.giver.id,
          'isOwnCollege': state.activeSession!.giver.isOwnCollege,
          'overlap': verification.overlapMinutes,
        },
      );
      state = state.copyWith(activeSession: completed);
    } else if (giverJoinedMin == 0) {
      // Giver no show -> auto refund
      state.ledgerEngine.refundCredit(
        studentId: state.activeSession!.student.id,
        creditValue: state.activeSession!.creditValue,
        reason: 'Giver No-Show',
      );
      final refunded = state.sessionEngine.transitionState(
        state.activeSession!,
        SessionState.refunded,
      );
      state.eventLog.log(
        type: 'CreditRefunded',
        actor: 'Session Engine',
        description: 'Giver no-show: 100% credit refund restored to student wallet.',
        virtualTime: state.virtualClock.format(),
        payload: {'giverId': state.activeSession!.giver.id},
      );
      state = state.copyWith(activeSession: refunded);
    }
  }

  void submitSessionRating(double score, String feedback) {
    if (state.activeSession == null) return;
    final ratings = [score, 5.0, 4.5, 4.8]; // illustrative sample history
    final smoothed = state.ratingEngine.computeSmoothedRating(ratings);
    final band = state.ratingEngine.getBand(
      completedSessions: state.activeSession!.giver.sessionCount + 1,
      smoothedRating: smoothed,
      completionRate: 0.95,
    );

    state.eventLog.log(
      type: 'RatingSubmitted',
      actor: 'Student',
      description: 'Student rated session: ${score.toStringAsFixed(1)} stars ("$feedback"). Smoothed rating: ${smoothed.toStringAsFixed(2)}',
      virtualTime: state.virtualClock.format(),
      payload: {'score': score, 'feedback': feedback, 'smoothed': smoothed},
    );

    state = state.copyWith(latestSmoothedRating: smoothed, latestBand: band);
  }
}

final demoControllerProvider =
    StateNotifierProvider<DemoController, DemoState>((ref) => DemoController());
