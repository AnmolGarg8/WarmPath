// allow-mock-file: guided demo, simulated and labelled
import '../data/personas.dart';
import '../models/demo_event_log.dart';

// --- Safety Engine Models & Contract ---
enum SafetyAction { allow, warn, block, review }

class SafetyScanResult {
  final SafetyAction action;
  final List<String> triggeredRules;
  final String maskedMessage;
  final String explanation;

  const SafetyScanResult({
    required this.action,
    required this.triggeredRules,
    required this.maskedMessage,
    required this.explanation,
  });
}

class VerificationResult {
  final bool isApproved;
  final String institutionName;
  final String badge;
  final String privileges;

  const VerificationResult({
    required this.isApproved,
    required this.institutionName,
    required this.badge,
    required this.privileges,
  });
}

class PrivilegeResult {
  final bool allowed;
  final int dailyLimit;
  final int remainingToday;
  final String reason;

  const PrivilegeResult({
    required this.allowed,
    required this.dailyLimit,
    required this.remainingToday,
    required this.reason,
  });
}

abstract class SafetyEngine {
  SafetyScanResult scanMessage(String text);
  String maskContactInfo(String text);
  VerificationResult verifyEmail(String email);
  PrivilegeResult checkDailyLimits(String trustLevel, int usedToday);
}

// --- Matching Engine Models & Contract ---
class RankedGiver {
  final SamplePersona persona;
  final double totalScore;
  final Map<String, double> componentScores;
  final List<String> whyLines;
  final bool isGated;
  final String? gateReason;

  const RankedGiver({
    required this.persona,
    required this.totalScore,
    required this.componentScores,
    required this.whyLines,
    this.isGated = false,
    this.gateReason,
  });
}

class MatchingResult {
  final List<RankedGiver> candidates;
  final List<RankedGiver> excludedByGates;

  const MatchingResult({
    required this.candidates,
    required this.excludedByGates,
  });
}

abstract class MatchingEngine {
  MatchingResult rankGivers({
    required List<String> studentSkills,
    required String intent,
    required bool capacityGateEnabled,
    required bool safetyGateEnabled,
  });
}

// --- Rating Engine Models & Contract ---
enum GiverBand { rising, trusted, topRated }

class RatingRecord {
  final String id;
  final String raterId;
  final String rateeId;
  final double score;
  final String feedback;
  final DateTime timestamp;

  const RatingRecord({
    required this.id,
    required this.raterId,
    required this.rateeId,
    required this.score,
    required this.feedback,
    required this.timestamp,
  });
}

class IntegrityCheckResult {
  final bool hasSuspiciousPattern;
  final String anomalyType;
  final double adjustedRating;
  final String explanation;

  const IntegrityCheckResult({
    required this.hasSuspiciousPattern,
    required this.anomalyType,
    required this.adjustedRating,
    required this.explanation,
  });
}

abstract class RatingEngine {
  double computeSmoothedRating(List<double> ratings);
  GiverBand getBand({
    required int completedSessions,
    required double smoothedRating,
    required double completionRate,
  });
  double calculatePayout(double creditValue, String band);
  IntegrityCheckResult checkRatingsIntegrity(List<RatingRecord> ratings);
}

// --- Session Engine Models & Contract ---
enum SessionState {
  scheduled,
  inProgress,
  completed,
  noShow,
  disputeWindow,
  settled,
  refunded,
}

class DemoSession {
  final String id;
  final SamplePersona student;
  final SamplePersona giver;
  final SessionState state;
  final DateTime scheduledAt;
  final int durationMinutes;
  final int studentJoinedMinutes;
  final int giverJoinedMinutes;
  final double creditValue;
  final bool isCreditReserved;

  const DemoSession({
    required this.id,
    required this.student,
    required this.giver,
    required this.state,
    required this.scheduledAt,
    this.durationMinutes = 20,
    this.studentJoinedMinutes = 0,
    this.giverJoinedMinutes = 0,
    required this.creditValue,
    this.isCreditReserved = true,
  });

  DemoSession copyWith({
    SessionState? state,
    int? studentJoinedMinutes,
    int? giverJoinedMinutes,
    bool? isCreditReserved,
  }) {
    return DemoSession(
      id: id,
      student: student,
      giver: giver,
      state: state ?? this.state,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      studentJoinedMinutes: studentJoinedMinutes ?? this.studentJoinedMinutes,
      giverJoinedMinutes: giverJoinedMinutes ?? this.giverJoinedMinutes,
      creditValue: creditValue,
      isCreditReserved: isCreditReserved ?? this.isCreditReserved,
    );
  }
}

class SessionCompletionResult {
  final bool isCompleted;
  final int overlapMinutes;
  final String statusDescription;

  const SessionCompletionResult({
    required this.isCompleted,
    required this.overlapMinutes,
    required this.statusDescription,
  });
}

abstract class SessionEngine {
  DemoSession createInstantRequest(SamplePersona giver, double creditValue);
  DemoSession acceptRequest(DemoSession session);
  SessionCompletionResult verifyCompletion({
    required int studentJoinedMin,
    required int giverJoinedMin,
  });
  DemoSession transitionState(DemoSession session, SessionState newState);
}

// --- Ledger Engine Models & Contract ---
enum LedgerAccount {
  studentPaidCredits,
  studentAffinityCredits,
  reservedEscrow,
  giverEarnings,
  platformRevenue,
  scholarshipPool,
}

class LedgerEntry {
  final String id;
  final String transactionId;
  final LedgerAccount account;
  final double amount; // Positive = credit/increase, Negative = debit/decrease
  final String description;
  final DateTime timestamp;

  const LedgerEntry({
    required this.id,
    required this.transactionId,
    required this.account,
    required this.amount,
    required this.description,
    required this.timestamp,
  });
}

abstract class LedgerEngine {
  List<LedgerEntry> getEntries();
  bool verifyZeroSum();
  void recordCampusFreeSession({required String studentId, required String giverId});
  void reservePaidCredit({
    required String studentId,
    required double creditValue,
    required String planId,
  });
  void settleCreditWithBandPayout({
    required String studentId,
    required String giverId,
    required double creditValue,
    required String band,
  });
  void refundCredit({
    required String studentId,
    required double creditValue,
    required String reason,
  });
}

// --- Institution Engine Models & Contract ---
class InstitutionDashboardMetrics {
  final int requestsPosted;
  final int requestsFulfilled;
  final int requestsExpired;
  final double avgFirstResponseMinutes;
  final int sessionsCompleted;
  final double averageRating;
  final int activeGivers;
  final double ownCollegeSharePercent;
  final double crossCollegeSharePercent;
  final Map<String, int> topRequestedSkills;
  final Map<String, int> topOfferedSkills;
  final List<String> skillGaps;
  final int safetyReportsCount;
  final int scamsBlockedCount;
  final double avgResolutionHours;
  final int sponsoredSeatsAllocated;
  final int sponsoredSeatsUsed;

  const InstitutionDashboardMetrics({
    required this.requestsPosted,
    required this.requestsFulfilled,
    required this.requestsExpired,
    required this.avgFirstResponseMinutes,
    required this.sessionsCompleted,
    required this.averageRating,
    required this.activeGivers,
    required this.ownCollegeSharePercent,
    required this.crossCollegeSharePercent,
    required this.topRequestedSkills,
    required this.topOfferedSkills,
    required this.skillGaps,
    required this.safetyReportsCount,
    required this.scamsBlockedCount,
    required this.avgResolutionHours,
    required this.sponsoredSeatsAllocated,
    required this.sponsoredSeatsUsed,
  });
}

abstract class InstitutionEngine {
  InstitutionDashboardMetrics computeMetrics(DemoEventLog log);
}
