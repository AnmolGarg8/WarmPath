import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/demo/engine/matching_engine_impl.dart';

void main() {
  group('MatchingEngine Tests (Pillar 1)', () {
    final engine = MatchingEngineImpl();

    test('Hard gates exclude 0-capacity and unverified givers with exact reasons', () {
      final res = engine.rankGivers(
        studentSkills: ['Python', 'SQL'],
        intent: 'Resume review',
        capacityGateEnabled: true,
        safetyGateEnabled: true,
      );

      // Sanjay has 0 capacity, Vikram is unverified
      expect(res.excludedByGates.length, 2);

      final sanjay = res.excludedByGates.firstWhere((g) => g.persona.id == 'sample_giver_sanjay');
      expect(sanjay.gateReason, contains('Weekly capacity reached'));

      final vikram = res.excludedByGates.firstWhere((g) => g.persona.id == 'sample_giver_vikram');
      expect(vikram.gateReason, contains('Trust safety check failed'));
    });

    test('Toggling capacity gate brings 0-capacity giver back into ranking', () {
      final resWithGate = engine.rankGivers(
        studentSkills: ['Python', 'SQL'],
        intent: 'Resume review',
        capacityGateEnabled: true,
        safetyGateEnabled: true,
      );
      expect(resWithGate.candidates.any((c) => c.persona.id == 'sample_giver_sanjay'), isFalse);

      final resWithoutGate = engine.rankGivers(
        studentSkills: ['Python', 'SQL'],
        intent: 'Resume review',
        capacityGateEnabled: false,
        safetyGateEnabled: true,
      );
      expect(resWithoutGate.candidates.any((c) => c.persona.id == 'sample_giver_sanjay'), isTrue);
    });

    test('Candidates contain deterministic why-lines explaining match components', () {
      final res = engine.rankGivers(
        studentSkills: ['Python', 'SQL', 'FastAPI'],
        intent: 'Looking for backend architecture guidance & resume review',
        capacityGateEnabled: true,
        safetyGateEnabled: true,
      );

      expect(res.candidates, isNotEmpty);
      final top = res.candidates.first;

      expect(top.whyLines, isNotEmpty);
      expect(top.whyLines.any((w) => w.contains('skills')), isTrue);
      expect(top.totalScore, greaterThan(0.0));
      expect(top.componentScores.containsKey('Expertise (35%)'), isTrue);
      expect(top.componentScores.containsKey('Intent (25%)'), isTrue);
    });

    test('Reorders ranking when intent changes', () {
      // Intent 1: Backend & resume review -> favors Arjun (alumnus backend engineer offering resume review)
      final res1 = engine.rankGivers(
        studentSkills: ['Python', 'SQL', 'System Design'],
        intent: 'Resume review and coding interview',
        capacityGateEnabled: true,
        safetyGateEnabled: true,
      );

      // Intent 2: Machine Learning & startup research -> favors Dev (Top Rated AI researcher)
      final res2 = engine.rankGivers(
        studentSkills: ['Python', 'SQL', 'Machine Learning', 'Deep Learning'],
        intent: 'AI research and startup pitch',
        capacityGateEnabled: true,
        safetyGateEnabled: true,
      );

      expect(res1.candidates.first.persona.id, 'sample_giver_arjun');
      expect(res2.candidates.first.persona.id, 'sample_giver_dev');
    });
  });
}
