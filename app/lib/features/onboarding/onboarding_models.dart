class ResumeSkill {
  final String name;
  final String category;

  const ResumeSkill({
    required this.name,
    this.category = 'skill',
  });

  factory ResumeSkill.fromJson(dynamic json) {
    if (json is String) {
      return ResumeSkill(name: json);
    }
    if (json is Map) {
      return ResumeSkill(
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? 'skill',
      );
    }
    return ResumeSkill(name: json.toString());
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
  };
}

class ResumeProfile {
  final String? id;
  final List<ResumeSkill> skills;
  final List<String> domains;
  final String? rawText;
  final String? updatedAt;

  const ResumeProfile({
    this.id,
    this.skills = const [],
    this.domains = const [],
    this.rawText,
    this.updatedAt,
  });

  factory ResumeProfile.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'] as List? ?? [];
    return ResumeProfile(
      id: json['id']?.toString(),
      skills: rawSkills.map((s) => ResumeSkill.fromJson(s)).toList(),
      domains: (json['domains'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      rawText: json['raw_text']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'skills': skills.map((s) => s.toJson()).toList(),
    'domains': domains,
    if (rawText != null) 'raw_text': rawText,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}

class StudentIntent {
  final String intent;
  final List<String> targetRoles;
  final String? urgency;

  const StudentIntent({
    this.intent = '',
    this.targetRoles = const [],
    this.urgency,
  });

  factory StudentIntent.fromJson(Map<String, dynamic> json) {
    return StudentIntent(
      intent: json['intent']?.toString() ?? '',
      targetRoles: (json['target_roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      urgency: json['urgency']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'intent': intent,
    'target_roles': targetRoles,
    if (urgency != null) 'urgency': urgency,
  };
}
