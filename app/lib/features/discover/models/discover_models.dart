// Models for WarmPath Discover & Giver Card Recommendations

class RatingSummaryData {
  final String band;
  final double smoothedAvg;
  final int totalSessions;
  final double completionRate;

  RatingSummaryData({
    required this.band,
    required this.smoothedAvg,
    required this.totalSessions,
    required this.completionRate,
  });

  factory RatingSummaryData.fromJson(Map<String, dynamic> json) {
    return RatingSummaryData(
      band: json['band'] as String? ?? 'Rising',
      smoothedAvg: (json['smoothed_avg'] as num?)?.toDouble() ?? 4.0,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class AvailabilitySummaryData {
  final bool online;
  final int capacityLeft;

  AvailabilitySummaryData({
    required this.online,
    required this.capacityLeft,
  });

  factory AvailabilitySummaryData.fromJson(Map<String, dynamic> json) {
    return AvailabilitySummaryData(
      online: json['online'] as bool? ?? false,
      capacityLeft: (json['capacity_left'] as num?)?.toInt() ?? 3,
    );
  }
}

class GiverCardData {
  final String id;
  final String fullName;
  final String headline;
  final String? company;
  final String? roleTitle;
  final String? bio;
  final List<String> offers;
  final List<String> topics;
  final List<dynamic> skills;
  final List<String> domains;
  final List<String> languages;
  final List<String> badges;
  final String band;
  final RatingSummaryData ratingSummary;
  final AvailabilitySummaryData availabilitySummary;
  final List<String> whyLines;
  bool get isOwnCollege => !badges.contains('Cross-College');

  GiverCardData({
    required this.id,
    required this.fullName,
    required this.headline,
    this.company,
    this.roleTitle,
    this.bio,
    this.offers = const [],
    this.topics = const [],
    this.skills = const [],
    this.domains = const [],
    this.languages = const [],
    this.badges = const [],
    required this.band,
    required this.ratingSummary,
    required this.availabilitySummary,
    this.whyLines = const [],
  });

  factory GiverCardData.fromJson(Map<String, dynamic> json) {
    return GiverCardData(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] as String? ?? 'Verified Giver',
      headline: json['headline'] as String? ?? 'Alumni Mentor',
      company: json['company'] as String?,
      roleTitle: json['role_title'] as String?,
      bio: json['bio'] as String?,
      offers: (json['offers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      topics: (json['topics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      skills: (json['skills'] as List<dynamic>?) ?? [],
      domains: (json['domains'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      languages: (json['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      badges: (json['badges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      band: json['band'] as String? ?? 'Rising',
      ratingSummary: json['rating_summary'] != null
          ? RatingSummaryData.fromJson(json['rating_summary'] as Map<String, dynamic>)
          : RatingSummaryData(band: 'Rising', smoothedAvg: 4.0, totalSessions: 0, completionRate: 1.0),
      availabilitySummary: json['availability_summary'] != null
          ? AvailabilitySummaryData.fromJson(json['availability_summary'] as Map<String, dynamic>)
          : AvailabilitySummaryData(online: false, capacityLeft: 3),
      whyLines: (json['why_lines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class RecommendationItemData {
  final GiverCardData giver;
  final List<String> whyLines;
  final bool locked;
  final String? lockReason;

  RecommendationItemData({
    required this.giver,
    required this.whyLines,
    this.locked = false,
    this.lockReason,
  });

  factory RecommendationItemData.fromJson(Map<String, dynamic> json) {
    final giverMap = json['giver'] as Map<String, dynamic>? ?? {};
    final whyList = (json['why_lines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        (giverMap['why_lines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [];

    return RecommendationItemData(
      giver: GiverCardData.fromJson(giverMap),
      whyLines: whyList,
      locked: json['locked'] as bool? ?? false,
      lockReason: json['lock_reason'] as String?,
    );
  }
}

class RecommendationsData {
  final List<RecommendationItemData> items;
  final String? nextCursor;
  final String scope;
  final bool locked;
  final String? lockReason;

  RecommendationsData({
    required this.items,
    this.nextCursor,
    required this.scope,
    this.locked = false,
    this.lockReason,
  });

  factory RecommendationsData.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((i) => RecommendationItemData.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];

    return RecommendationsData(
      items: itemsList,
      nextCursor: json['next_cursor'] as String?,
      scope: json['scope'] as String? ?? 'own_college',
      locked: json['locked'] as bool? ?? false,
      lockReason: json['lock_reason'] as String?,
    );
  }
}
