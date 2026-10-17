// Models for WarmPath Student & Giver Onboarding

class ConsentItem {
  final String purpose;
  final String title;
  final String description;
  bool granted;

  ConsentItem({
    required this.purpose,
    required this.title,
    required this.description,
    this.granted = false,
  });

  Map<String, dynamic> toJson() => {
        'purpose': purpose,
        'granted': granted,
      };

  factory ConsentItem.fromJson(Map<String, dynamic> json) {
    return ConsentItem(
      purpose: json['purpose'] as String,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      granted: json['granted'] as bool? ?? false,
    );
  }
}

class ParsedEducation {
  String degree;
  String institution;
  String fieldOfStudy;
  int? startYear;
  int? endYear;
  String? gpa;

  ParsedEducation({
    required this.degree,
    required this.institution,
    required this.fieldOfStudy,
    this.startYear,
    this.endYear,
    this.gpa,
  });

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'institution': institution,
        'field_of_study': fieldOfStudy,
        'start_year': startYear,
        'end_year': endYear,
        'gpa': gpa,
      };

  factory ParsedEducation.fromJson(Map<String, dynamic> json) {
    return ParsedEducation(
      degree: json['degree'] as String? ?? '',
      institution: json['institution'] as String? ?? '',
      fieldOfStudy: json['field_of_study'] as String? ?? '',
      startYear: json['start_year'] as int?,
      endYear: json['end_year'] as int?,
      gpa: json['gpa']?.toString(),
    );
  }
}

class ParsedSkill {
  String name;
  String category;
  double confidence;

  ParsedSkill({
    required this.name,
    this.category = 'Other',
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'confidence': confidence,
      };

  factory ParsedSkill.fromJson(Map<String, dynamic> json) {
    return ParsedSkill(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class ParsedProject {
  String title;
  String description;
  List<String> tech;

  ParsedProject({
    required this.title,
    required this.description,
    this.tech = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'tech': tech,
      };

  factory ParsedProject.fromJson(Map<String, dynamic> json) {
    return ParsedProject(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tech: (json['tech'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class ParsedProfile {
  List<ParsedEducation> education;
  List<ParsedSkill> skills;
  List<String> domains;
  List<ParsedProject> projects;
  String experienceLevel;
  double confidence;

  ParsedProfile({
    this.education = const [],
    this.skills = const [],
    this.domains = const [],
    this.projects = const [],
    this.experienceLevel = 'student',
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'education': education.map((e) => e.toJson()).toList(),
        'skills': skills.map((s) => s.toJson()).toList(),
        'domains': domains,
        'projects': projects.map((p) => p.toJson()).toList(),
        'experience_level': experienceLevel,
        'confidence': confidence,
      };

  factory ParsedProfile.fromJson(Map<String, dynamic> json) {
    final eduList = (json['education'] as List<dynamic>?)
            ?.map((e) => ParsedEducation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final skillList = (json['skills'] as List<dynamic>?)
            ?.map((s) {
              if (s is Map<String, dynamic>) {
                return ParsedSkill.fromJson(s);
              }
              return ParsedSkill(name: s.toString());
            })
            .toList() ??
        [];

    final domList = (json['domains'] as List<dynamic>?)
            ?.map((d) => d.toString())
            .toList() ??
        [];

    final projList = (json['projects'] as List<dynamic>?)
            ?.map((p) => ParsedProject.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return ParsedProfile(
      education: eduList,
      skills: skillList,
      domains: domList,
      projects: projList,
      experienceLevel: json['experience_level'] as String? ?? 'student',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class StructuredIntent {
  String goal;
  List<String> roles;
  List<String> domains;
  String urgency;
  String helpType;

  StructuredIntent({
    required this.goal,
    this.roles = const [],
    this.domains = const [],
    this.urgency = 'normal',
    this.helpType = 'resume_review',
  });

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'roles': roles,
        'domains': domains,
        'urgency': urgency,
        'help_type': helpType,
      };

  factory StructuredIntent.fromJson(Map<String, dynamic> json) {
    return StructuredIntent(
      goal: json['goal'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      domains: (json['domains'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      urgency: json['urgency'] as String? ?? 'normal',
      helpType: json['help_type'] as String? ?? 'resume_review',
    );
  }
}
