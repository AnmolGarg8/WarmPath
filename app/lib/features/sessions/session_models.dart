class CounterpartSummary {
  final String id;
  final String displayName;
  final String? headline;
  final String? avatarUrl;
  final String? role; // 'Giver' or 'Student'
  final List<String> badges;
  final String? band; // 'Rising', 'Trusted', 'Top Rated'

  const CounterpartSummary({
    required this.id,
    required this.displayName,
    this.headline,
    this.avatarUrl,
    this.role,
    this.badges = const [],
    this.band,
  });

  factory CounterpartSummary.fromJson(Map<String, dynamic> json) {
    return CounterpartSummary(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'WarmPath Member',
      headline: json['headline']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      role: json['role']?.toString(),
      badges: (json['badges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      band: json['band']?.toString(),
    );
  }
}

class MentorshipRequest {
  final String id;
  final String studentId;
  final String giverId;
  final String kind; // 'instant' or 'booked'
  final String intentText;
  final DateTime? slotStart;
  final String status; // 'pending', 'accepted', 'declined', 'expired', 'cancelled'
  final int priority; // 3=Premium, 2=High, 1=Standard
  final String? planName;
  final bool isCrossCollege;
  final DateTime createdAt;
  final CounterpartSummary? counterpart;
  final String? giverEarningsText;

  const MentorshipRequest({
    required this.id,
    required this.studentId,
    required this.giverId,
    required this.kind,
    required this.intentText,
    this.slotStart,
    required this.status,
    this.priority = 1,
    this.planName,
    this.isCrossCollege = false,
    required this.createdAt,
    this.counterpart,
    this.giverEarningsText,
  });

  factory MentorshipRequest.fromJson(Map<String, dynamic> json) {
    return MentorshipRequest(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      giverId: json['giver_id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'instant',
      intentText: json['intent_text']?.toString() ?? '',
      slotStart: json['slot_start'] != null ? DateTime.tryParse(json['slot_start'].toString()) : null,
      status: json['status']?.toString() ?? 'pending',
      priority: json['priority'] as int? ?? 1,
      planName: json['plan_name']?.toString(),
      isCrossCollege: json['is_cross_college'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      counterpart: json['counterpart'] != null ? CounterpartSummary.fromJson(json['counterpart'] as Map<String, dynamic>) : null,
      giverEarningsText: json['giver_earnings_text']?.toString(),
    );
  }
}

class CallSession {
  final String id;
  final String requestId;
  final String studentId;
  final String giverId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String roomUrl;
  final String status; // 'scheduled', 'in_progress', 'completed', 'no_show'
  final DateTime? studentJoinedAt;
  final DateTime? giverJoinedAt;
  final String? noShowParty;
  final CounterpartSummary? counterpart;
  final String? topic;
  final int? studentRatingStars;
  final bool giverRatedQuality;

  const CallSession({
    required this.id,
    required this.requestId,
    required this.studentId,
    required this.giverId,
    required this.scheduledAt,
    this.durationMinutes = 20,
    required this.roomUrl,
    required this.status,
    this.studentJoinedAt,
    this.giverJoinedAt,
    this.noShowParty,
    this.counterpart,
    this.topic,
    this.studentRatingStars,
    this.giverRatedQuality = false,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) {
    return CallSession(
      id: json['id']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      giverId: json['giver_id']?.toString() ?? '',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      durationMinutes: json['duration_minutes'] as int? ?? 20,
      roomUrl: json['room_url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'scheduled',
      studentJoinedAt: json['student_joined_at'] != null ? DateTime.tryParse(json['student_joined_at'].toString()) : null,
      giverJoinedAt: json['giver_joined_at'] != null ? DateTime.tryParse(json['giver_joined_at'].toString()) : null,
      noShowParty: json['no_show_party']?.toString(),
      counterpart: json['counterpart'] != null ? CounterpartSummary.fromJson(json['counterpart'] as Map<String, dynamic>) : null,
      topic: json['topic']?.toString(),
      studentRatingStars: json['student_rating_stars'] as int?,
      giverRatedQuality: json['giver_rated_quality'] as bool? ?? false,
    );
  }
}

class SlotItem {
  final DateTime slotStart;
  final DateTime slotEnd;
  final bool available;

  const SlotItem({
    required this.slotStart,
    required this.slotEnd,
    required this.available,
  });

  factory SlotItem.fromJson(Map<String, dynamic> json) {
    return SlotItem(
      slotStart: json['slot_start'] != null ? DateTime.parse(json['slot_start'].toString()) : DateTime.now(),
      slotEnd: json['slot_end'] != null ? DateTime.parse(json['slot_end'].toString()) : DateTime.now(),
      available: json['available'] as bool? ?? true,
    );
  }
}

class ThreadMessage {
  final String id;
  final String requestId;
  final String senderId;
  final String content;
  final String safetyAction; // 'allow', 'warn', 'review', 'block'
  final List<String> flags;
  final DateTime createdAt;

  const ThreadMessage({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.content,
    required this.safetyAction,
    this.flags = const [],
    required this.createdAt,
  });

  factory ThreadMessage.fromJson(Map<String, dynamic> json) {
    return ThreadMessage(
      id: json['id']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      safetyAction: json['safety_action']?.toString() ?? 'allow',
      flags: (json['flags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
