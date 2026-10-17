class RatingSummary {
  final String band;
  final double smoothedAvg;
  final int totalSessions;
  final double completionRate;

  const RatingSummary({
    required this.band,
    required this.smoothedAvg,
    required this.totalSessions,
    required this.completionRate,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      band: json['band']?.toString() ?? 'Rising',
      smoothedAvg: (json['smoothed_avg'] as num?)?.toDouble() ?? 4.0,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class AvailabilitySummary {
  final bool online;
  final int capacityLeft;

  const AvailabilitySummary({
    required this.online,
    required this.capacityLeft,
  });

  factory AvailabilitySummary.fromJson(Map<String, dynamic> json) {
    return AvailabilitySummary(
      online: json['online'] as bool? ?? false,
      capacityLeft: (json['capacity_left'] as num?)?.toInt() ?? 3,
    );
  }
}

class GiverPublicCard {
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
  final List<String> badges;
  final String band;
  final RatingSummary? ratingSummary;
  final AvailabilitySummary? availabilitySummary;
  final List<String> whyLines;

  const GiverPublicCard({
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
    this.badges = const [],
    required this.band,
    this.ratingSummary,
    this.availabilitySummary,
    this.whyLines = const [],
  });

  factory GiverPublicCard.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'];
    final List<dynamic> parsedSkills = [];
    if (rawSkills is List) {
      for (final s in rawSkills) {
        if (s is Map) {
          parsedSkills.add(s['name']?.toString() ?? s.toString());
        } else {
          parsedSkills.add(s.toString());
        }
      }
    }

    return GiverPublicCard(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Verified Alumni',
      headline: json['headline']?.toString() ?? '',
      company: json['company']?.toString(),
      roleTitle: json['role_title']?.toString(),
      bio: json['bio']?.toString(),
      offers: (json['offers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      topics: (json['topics'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      skills: parsedSkills,
      domains: (json['domains'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      badges: (json['badges'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      band: json['band']?.toString() ?? 'Rising',
      ratingSummary: json['rating_summary'] != null
          ? RatingSummary.fromJson(json['rating_summary'] as Map<String, dynamic>)
          : null,
      availabilitySummary: json['availability_summary'] != null
          ? AvailabilitySummary.fromJson(json['availability_summary'] as Map<String, dynamic>)
          : null,
      whyLines: (json['why_lines'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class RecommendationItem {
  final GiverPublicCard giver;
  final List<String> whyLines;
  final bool locked;
  final String? lockReason;

  const RecommendationItem({
    required this.giver,
    this.whyLines = const [],
    this.locked = false,
    this.lockReason,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      giver: GiverPublicCard.fromJson(json['giver'] as Map<String, dynamic>),
      whyLines: (json['why_lines'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      locked: json['locked'] as bool? ?? false,
      lockReason: json['lock_reason']?.toString(),
    );
  }
}

class RecommendationsResponse {
  final List<RecommendationItem> items;
  final String? nextCursor;
  final String scope;
  final bool locked;
  final String? lockReason;

  const RecommendationsResponse({
    required this.items,
    this.nextCursor,
    required this.scope,
    this.locked = false,
    this.lockReason,
  });

  factory RecommendationsResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return RecommendationsResponse(
      items: rawItems.map((e) => RecommendationItem.fromJson(e as Map<String, dynamic>)).toList(),
      nextCursor: json['next_cursor']?.toString(),
      scope: json['scope']?.toString() ?? 'own_college',
      locked: json['locked'] as bool? ?? false,
      lockReason: json['lock_reason']?.toString(),
    );
  }
}
