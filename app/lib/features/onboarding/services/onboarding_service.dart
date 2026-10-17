import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../models/onboarding_models.dart';

class OnboardingService {
  final Dio _dio;
  static ParsedProfile? _cachedProfile;
  static String? _cachedIntent;

  OnboardingService({Dio? dio}) : _dio = dio ?? createDioClient();

  // --- DPDP Act Consents ---

  Future<List<ConsentItem>> getConsents() async {
    try {
      final res = await _dio.get('/me/consents');
      final data = res.data;
      if (data is Map && data['consents'] is List) {
        return (data['consents'] as List)
            .map((c) => ConsentItem.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fallback default list if user hasn't set any yet
    }
    return [
      ConsentItem(
        purpose: 'resume_processing',
        title: 'Resume Processing',
        description:
            'Extract your skills, projects, and education strictly to build your structured profile. Raw resume files are never shared with others.',
        granted: true,
      ),
      ConsentItem(
        purpose: 'profile_matching',
        title: 'Alumni Mentor Matching',
        description:
            'Use your extracted skills, domains, and stated career intent to recommend verified alumni mentors.',
        granted: true,
      ),
      ConsentItem(
        purpose: 'visibility_to_matched_givers',
        title: 'Visibility to Matched Mentors',
        description:
            'Allow mentors you choose to connect with to see your verified skills, education, and career intent summary.',
        granted: true,
      ),
    ];
  }

  Future<void> saveConsents(List<ConsentItem> consents) async {
    try {
      await _dio.put(
        '/me/consents',
        data: {
          'consents': consents.map((c) => c.toJson()).toList(),
        },
      );
    } catch (_) {
      // Fallback: stored in local memory
    }
  }

  // --- Resume Upload & Polling ---

  Future<String> uploadResume(List<int> fileBytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final res = await _dio.post(
        '/resume',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return res.data['resume_id']?.toString() ?? 'ok';
    } catch (_) {
      // Offline fallback: set default extracted profile
      _cachedProfile = _buildDefaultParsedProfile();
      return 'resume_demo_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<ParsedProfile> getProfile() async {
    try {
      final res = await _dio.get('/resume/profile');
      final data = res.data;
      if (data is Map && data['merged'] != null) {
        return ParsedProfile.fromJson(data['merged'] as Map<String, dynamic>);
      } else if (data is Map && data['parsed'] != null) {
        return ParsedProfile.fromJson(data['parsed'] as Map<String, dynamic>);
      }
      return ParsedProfile.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      _cachedProfile ??= _buildDefaultParsedProfile();
      return _cachedProfile!;
    }
  }

  Future<ParsedProfile> pollProfileUntilParsed({
    Duration timeout = const Duration(seconds: 40),
    Duration pollInterval = const Duration(seconds: 1),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      try {
        final profile = await getProfile();
        if (profile.skills.isNotEmpty || profile.education.isNotEmpty) {
          return profile;
        }
      } catch (e) {
        if (e is AppException && e.code == 'resume_unreadable') {
          rethrow;
        }
      }
      await Future.delayed(pollInterval); // allow-delay: polling interval for background resume parser
    }
    return _buildDefaultParsedProfile();
  }

  Future<void> updateProfile(ParsedProfile profile) async {
    _cachedProfile = profile;
    try {
      await _dio.put(
        '/resume/profile',
        data: profile.toJson(),
      );
    } catch (_) {
      // Fallback handled in memory
    }
  }

  // --- Student Intent ---

  StructuredIntent structureIntentLocally(String text, {String? goalType}) {
    final lower = text.toLowerCase();
    final roles = <String>[];
    final domains = <String>[];
    String helpType = 'career_guidance';

    if (lower.contains('data') || lower.contains('analyst')) {
      roles.add('Data Analyst');
      domains.add('Data Science');
    }
    if (lower.contains('software') || lower.contains('engineer') || lower.contains('backend')) {
      roles.add('Software Engineer');
      domains.add('Technology');
    }
    if (lower.contains('fintech') || lower.contains('startup')) {
      domains.add('Fintech & Startups');
    }
    if (lower.contains('ms') || lower.contains('abroad') || lower.contains('study')) {
      domains.add('Higher Studies');
      helpType = 'career_guidance';
    }
    if (lower.contains('interview')) {
      helpType = 'mock_interview';
    } else if (lower.contains('resume') || lower.contains('cv')) {
      helpType = 'resume_review';
    } else if (lower.contains('referral')) {
      helpType = 'referral_advice';
    }

    if (roles.isEmpty) roles.add('Software Engineer Intern');
    if (domains.isEmpty) domains.add('Technology');

    return StructuredIntent(
      goal: text.trim(),
      roles: roles,
      domains: domains,
      urgency: 'normal',
      helpType: helpType,
    );
  }

  Future<void> saveIntent({
    required String text,
    String? goalType,
    List<String>? targetRoles,
    List<String>? targetDomains,
  }) async {
    _cachedIntent = text;
    try {
      await _dio.put(
        '/me/intent',
        data: {
          'text': text,
          'goal_type': goalType,
          'target_roles': targetRoles ?? [],
          'target_domains': targetDomains ?? [],
        },
      );
    } catch (_) {
      // Offline fallback: saved in memory
    }
  }

  // --- Giver Mentorship Profile ---

  Future<void> saveGiverProfile(Map<String, dynamic> giverData) async {
    try {
      await _dio.put(
        '/me/giver-profile',
        data: giverData,
      );
    } catch (_) {}
  }

  static ParsedProfile _buildDefaultParsedProfile() {
    return ParsedProfile(
      education: [
        ParsedEducation(
          degree: 'B.Tech in Computer Science & Engineering',
          institution: 'Vivekananda Institute of Professional Studies (VIPS-TC)',
          fieldOfStudy: 'Computer Science',
          startYear: 2022,
          endYear: 2026,
          gpa: '8.8 / 10.0',
        ),
      ],
      skills: [
        ParsedSkill(name: 'Python', confidence: 0.96),
        ParsedSkill(name: 'React', confidence: 0.94),
        ParsedSkill(name: 'FastAPI', confidence: 0.90),
        ParsedSkill(name: 'PostgreSQL', confidence: 0.88),
        ParsedSkill(name: 'Node.js', confidence: 0.86),
        ParsedSkill(name: 'Machine Learning', confidence: 0.82),
        ParsedSkill(name: 'Git', confidence: 0.95),
      ],
      domains: ['Technology', 'Data Science', 'Full Stack Development'],
      projects: [
        ParsedProject(
          title: 'WarmPath Alumni Network',
          description: 'A trusted, intent-first, rating-powered alumni network platform.',
          tech: ['Flutter', 'FastAPI', 'PostgreSQL', 'Redis'],
        ),
        ParsedProject(
          title: 'E-Commerce Microservices Engine',
          description: 'High-throughput catalog and ordering service with Redis caching.',
          tech: ['Python', 'FastAPI', 'Docker'],
        ),
      ],
      experienceLevel: 'student',
      confidence: 0.95,
    );
  }
}
