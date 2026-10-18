// allow-mock-file: guided demo, simulated and labelled
import '../models/demo_event_log.dart';
import 'contracts.dart';

class InstitutionEngineImpl implements InstitutionEngine {
  @override
  InstitutionDashboardMetrics computeMetrics(DemoEventLog log) {
    // Baseline simulated numbers from historical campus activity (labelled illustrative)
    int requestsPosted = 42;
    int requestsFulfilled = 38;
    int requestsExpired = 4;
    double avgResponseMin = 18.5;
    int sessionsCompleted = 35;
    double totalRatingSum = 35 * 4.8;
    int ratingCount = 35;
    int activeGivers = 12;
    int ownCollegeCount = 28;
    int crossCollegeCount = 7;
    int safetyReports = 1;
    int scamsBlocked = 4;
    int seatsAllocated = 10;
    int seatsUsed = 6;

    // Baseline skills
    final Map<String, int> requestedSkills = {
      'Python': 28,
      'Machine Learning': 24,
      'System Design': 20,
      'Kubernetes': 18,
      'Cloud Architecture': 15,
      'SQL': 12,
    };

    final Map<String, int> offeredSkills = {
      'Python': 25,
      'SQL': 22,
      'PostgreSQL': 18,
      'Docker': 15,
      'System Design': 8, // Gap!
      'Kubernetes': 6, // Gap!
      'Cloud Architecture': 5, // Gap!
    };

    // Dynamically fold in events recorded during this demo run
    for (final event in log.events) {
      switch (event.type) {
        case 'RequestCreated':
          requestsPosted += 1;
          break;
        case 'RequestAccepted':
          requestsFulfilled += 1;
          break;
        case 'SessionCompleted':
          sessionsCompleted += 1;
          final isOwn = event.payload['isOwnCollege'] as bool? ?? true;
          if (isOwn) {
            ownCollegeCount += 1;
          } else {
            crossCollegeCount += 1;
          }
          break;
        case 'RatingSubmitted':
          final score = (event.payload['score'] as num?)?.toDouble() ?? 5.0;
          totalRatingSum += score;
          ratingCount += 1;
          break;
        case 'ScamBlocked':
          scamsBlocked += 1;
          break;
        case 'ModerationReported':
          safetyReports += 1;
          break;
        case 'SeatClaimed':
          seatsUsed += 1;
          break;
        case 'IntentSet':
          final domain = event.payload['domain'] as String? ?? 'Cloud Architecture';
          requestedSkills[domain] = (requestedSkills[domain] ?? 0) + 1;
          break;
      }
    }

    final double avgRating = ratingCount > 0 ? (totalRatingSum / ratingCount) : 4.8;
    final int totalSessions = ownCollegeCount + crossCollegeCount;
    final double ownShare = totalSessions > 0 ? (ownCollegeCount / totalSessions) * 100 : 80.0;
    final double crossShare = 100.0 - ownShare;

    // Calculate skill gaps
    final List<String> gaps = [];
    requestedSkills.forEach((skill, reqCount) {
      final offCount = offeredSkills[skill] ?? 0;
      if (reqCount - offCount >= 8) {
        gaps.add('$skill (Demand: $reqCount, Campus Supply: $offCount - Gap: +${reqCount - offCount})');
      }
    });

    return InstitutionDashboardMetrics(
      requestsPosted: requestsPosted,
      requestsFulfilled: requestsFulfilled,
      requestsExpired: requestsExpired,
      avgFirstResponseMinutes: avgResponseMin,
      sessionsCompleted: sessionsCompleted,
      averageRating: avgRating,
      activeGivers: activeGivers,
      ownCollegeSharePercent: ownShare,
      crossCollegeSharePercent: crossShare,
      topRequestedSkills: requestedSkills,
      topOfferedSkills: offeredSkills,
      skillGaps: gaps,
      safetyReportsCount: safetyReports,
      scamsBlockedCount: scamsBlocked,
      avgResolutionHours: 2.4, // Well within 24h target
      sponsoredSeatsAllocated: seatsAllocated,
      sponsoredSeatsUsed: seatsUsed,
    );
  }
}
