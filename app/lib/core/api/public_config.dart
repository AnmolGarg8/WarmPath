import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';

class PublicConfig {
  final bool demoProfile;
  final bool testMode;
  final int disputeMinutes;
  final int noReplyMinutes;
  final int minCallSeconds;
  final bool loweredBandThresholds;
  final int trustedMinSessions;
  final int topRatedMinSessions;

  const PublicConfig({
    required this.demoProfile,
    required this.testMode,
    required this.disputeMinutes,
    required this.noReplyMinutes,
    required this.minCallSeconds,
    this.loweredBandThresholds = false,
    this.trustedMinSessions = 5,
    this.topRatedMinSessions = 10,
  });

  factory PublicConfig.fromJson(Map<String, dynamic> json) {
    final windows = json['windows'] as Map<String, dynamic>? ?? {};
    final thresholds = json['band_thresholds'] as Map<String, dynamic>? ?? {};

    return PublicConfig(
      demoProfile: json['demo_profile'] as bool? ?? false,
      testMode: json['test_mode'] as bool? ?? true,
      disputeMinutes: (windows['dispute_minutes'] as num?)?.toInt() ?? 2880,
      noReplyMinutes: (windows['no_reply_minutes'] as num?)?.toInt() ?? 4320,
      minCallSeconds: (windows['min_call_seconds'] as num?)?.toInt() ?? 300,
      loweredBandThresholds: thresholds['lowered'] as bool? ?? false,
      trustedMinSessions: (thresholds['trusted_min_sessions'] as num?)?.toInt() ?? 5,
      topRatedMinSessions: (thresholds['top_rated_min_sessions'] as num?)?.toInt() ?? 10,
    );
  }
}

final publicConfigProvider = FutureProvider<PublicConfig>((ref) async {
  final dio = createDioClient();
  try {
    final response = await dio.get('/config/public');
    if (response.data is Map<String, dynamic>) {
      return PublicConfig.fromJson(response.data as Map<String, dynamic>);
    } else if (response.data is Map) {
      return PublicConfig.fromJson(Map<String, dynamic>.from(response.data as Map));
    }
  } catch (_) {
    // If backend is not available, default to production config with no banners
  }
  return const PublicConfig(
    demoProfile: false,
    testMode: true,
    disputeMinutes: 2880,
    noReplyMinutes: 4320,
    minCallSeconds: 300,
  );
});
