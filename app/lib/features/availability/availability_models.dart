class TimeWindow {
  final int weekday; // 0=Monday, 6=Sunday
  final String startTime; // "HH:MM"
  final String endTime; // "HH:MM"

  const TimeWindow({
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  factory TimeWindow.fromJson(Map<String, dynamic> json) {
    return TimeWindow(
      weekday: json['weekday'] as int? ?? 0,
      startTime: json['start_time'] as String? ?? '09:00',
      endTime: json['end_time'] as String? ?? '17:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  String get weekdayName {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (weekday >= 0 && weekday < days.length) {
      return days[weekday];
    }
    return 'Unknown';
  }

  String get weekdayShort {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday >= 0 && weekday < days.length) {
      return days[weekday];
    }
    return 'Day';
  }

  bool isValid() {
    if (weekday < 0 || weekday > 6) return false;
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    if (startParts.length != 2 || endParts.length != 2) return false;

    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    return startMinutes < endMinutes;
  }
}

class AvailabilityData {
  final String userId;
  final int weeklyCapacity;
  final String timezone;
  final List<TimeWindow> windows;
  final int usedThisWeek;
  final int capacityLeft;
  final DateTime? updatedAt;

  const AvailabilityData({
    required this.userId,
    required this.weeklyCapacity,
    required this.timezone,
    required this.windows,
    this.usedThisWeek = 0,
    this.capacityLeft = 0,
    this.updatedAt,
  });

  factory AvailabilityData.fromJson(Map<String, dynamic> json) {
    return AvailabilityData(
      userId: json['user_id']?.toString() ?? '',
      weeklyCapacity: json['weekly_capacity'] as int? ?? 5,
      timezone: json['timezone'] as String? ?? 'UTC',
      windows: (json['windows'] as List<dynamic>?)
              ?.map((w) => TimeWindow.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      usedThisWeek: json['used_this_week'] as int? ?? 0,
      capacityLeft: json['capacity_left'] as int? ?? 5,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekly_capacity': weeklyCapacity,
      'timezone': timezone,
      'windows': windows.map((w) => w.toJson()).toList(),
    };
  }

  AvailabilityData copyWith({
    String? userId,
    int? weeklyCapacity,
    String? timezone,
    List<TimeWindow>? windows,
    int? usedThisWeek,
    int? capacityLeft,
    DateTime? updatedAt,
  }) {
    return AvailabilityData(
      userId: userId ?? this.userId,
      weeklyCapacity: weeklyCapacity ?? this.weeklyCapacity,
      timezone: timezone ?? this.timezone,
      windows: windows ?? this.windows,
      usedThisWeek: usedThisWeek ?? this.usedThisWeek,
      capacityLeft: capacityLeft ?? this.capacityLeft,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class OnlineStatus {
  final String userId;
  final bool onlineNow;
  final DateTime? expiresAt;
  final int remainingSeconds;

  const OnlineStatus({
    required this.userId,
    required this.onlineNow,
    this.expiresAt,
    this.remainingSeconds = 0,
  });

  factory OnlineStatus.fromJson(Map<String, dynamic> json) {
    return OnlineStatus(
      userId: json['user_id']?.toString() ?? '',
      onlineNow: json['online_now'] as bool? ?? false,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      remainingSeconds: json['remaining_seconds'] as int? ?? 0,
    );
  }
}
