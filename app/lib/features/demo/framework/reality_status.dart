// allow-mock-file: guided demo, simulated and labelled

/// NOTE: In accordance with WarmPath honesty rules, an entry in this matrix
/// may be changed to 'live' ONLY after docs/VERIFICATION.md confirms it passed
/// automated tests against real backend services.
enum FeatureLiveStatus {
  live('Live in Backend', 0xFF15803D, 0xFFDCFCE7),
  partlyLive('Partly Live / Backend Router Wired', 0xFFB45309, 0xFFFEF3C7),
  simulated('Simulated in Demo', 0xFF1E3A8A, 0xFFDBEAFE);

  final String label;
  final int textColor;
  final int bgColor;

  const FeatureLiveStatus(this.label, this.textColor, this.bgColor);
}

class PillarRealityEntry {
  final int pillarNumber;
  final String title;
  final FeatureLiveStatus status;
  final String liveEvidence;
  final String simulatedAspects;

  const PillarRealityEntry({
    required this.pillarNumber,
    required this.title,
    required this.status,
    required this.liveEvidence,
    required this.simulatedAspects,
  });
}

class RealityStatusRegistry {
  static const List<PillarRealityEntry> entries = [
    PillarRealityEntry(
      pillarNumber: 1,
      title: 'Resume & Intent Matching',
      status: FeatureLiveStatus.partlyLive,
      liveEvidence:
          'Backend contracts/modules/matching.yaml implemented; pure heuristic formula (35/25/15/10/10/5) mathematically verified.',
      simulatedAspects:
          'Demo uses pre-extracted sample skill tags for Riya and sample givers. Live production model requires Gemini API key.',
    ),
    PillarRealityEntry(
      pillarNumber: 2,
      title: 'Free Affinity & Paid Reach',
      status: FeatureLiveStatus.partlyLive,
      liveEvidence:
          'Double-entry zero-sum ledger formula verified; plans and credit lot values mapped to backend contracts/modules/credits.yaml.',
      simulatedAspects:
          'Demo checkout simulates Razorpay payment sheet without network call. No actual bank money moves in demo.',
    ),
    PillarRealityEntry(
      pillarNumber: 3,
      title: 'Rating-Based Earning & Bands',
      status: FeatureLiveStatus.partlyLive,
      liveEvidence:
          'Bayesian smoothing formula: (5*4.0 + sum)/(5 + n) tested; band thresholds and 60%/70%/80% payout shares verified.',
      simulatedAspects:
          'Demo computes ratings and band updates in-memory using the exact backend formula.',
    ),
    PillarRealityEntry(
      pillarNumber: 4,
      title: 'Trust by Design & Moderation',
      status: FeatureLiveStatus.live,
      liveEvidence:
          'VERIFIED LIVE: Domain check, JWT rotation, graduated limits, scam scan rules, moderation SLA audit log, and DPDP deletion passed.',
      simulatedAspects:
          'Demo runs pure-Dart replica of the verified backend safety scanner for offline, zero-latency projector presentation.',
    ),
    PillarRealityEntry(
      pillarNumber: 5,
      title: 'Capacity-Aware Connect & Escrow',
      status: FeatureLiveStatus.partlyLive,
      liveEvidence:
          '48-hour dispute window and 72-hour no-reply auto-refund rules verified in contracts/modules/sessions.yaml.',
      simulatedAspects:
          'Video call is simulated with a visual timer (no WebRTC camera active in demo mode). Fast-forward button simulates 48 hours.',
    ),
    PillarRealityEntry(
      pillarNumber: 6,
      title: 'Institution Network View',
      status: FeatureLiveStatus.partlyLive,
      liveEvidence:
          'Analytics models and skill-gap aggregation logic verified in contracts/modules/institution.yaml.',
      simulatedAspects:
          'Dashboard in demo reads dynamically from the in-memory DemoEventLog and baseline campus stats.',
    ),
  ];
}
