import 'package:flutter_test/flutter_test.dart';
import '../models/onboarding_models.dart';
import '../services/onboarding_service.dart';

void main() {
  group('Onboarding Models & Review Form Mapping', () {
    test('ParsedProfile correctly maps from JSON with low confidence flags', () {
      final json = {
        'education': [
          {
            'degree': 'Bachelor of Technology',
            'institution': 'VIPS-TC',
            'field_of_study': 'Computer Science',
            'start_year': 2022,
            'end_year': 2026,
            'gpa': '8.9',
          }
        ],
        'skills': [
          {'name': 'Python', 'category': 'Programming Languages', 'confidence': 0.95},
          {'name': 'FastAPI', 'category': 'Web Frameworks', 'confidence': 0.90},
          {'name': 'Cobol', 'category': 'Other', 'confidence': 0.45}, // Low confidence
        ],
        'domains': ['Web Development', 'Fintech'],
        'projects': [
          {
            'title': 'Alumni Network',
            'description': 'Mentorship platform',
            'tech': ['Flutter', 'FastAPI'],
          }
        ],
        'experience_level': 'student',
        'confidence': 0.92,
      };

      final profile = ParsedProfile.fromJson(json);

      expect(profile.education.length, 1);
      expect(profile.education[0].degree, 'Bachelor of Technology');
      expect(profile.education[0].institution, 'VIPS-TC');
      expect(profile.education[0].gpa, '8.9');

      expect(profile.skills.length, 3);
      expect(profile.skills[0].name, 'Python');
      expect(profile.skills[0].confidence, 0.95);
      expect(profile.skills[2].name, 'Cobol');
      expect(profile.skills[2].confidence, 0.45);
      expect(profile.skills[2].confidence < 0.7, isTrue); // Triggers highlight

      expect(profile.domains, contains('Fintech'));
      expect(profile.projects.length, 1);
      expect(profile.projects[0].tech, contains('Flutter'));
      expect(profile.experienceLevel, 'student');
    });

    test('ParsedProfile serializes back to JSON correctly for PUT /resume/profile', () {
      final profile = ParsedProfile(
        education: [
          ParsedEducation(
            degree: 'B.Tech',
            institution: 'VIPS',
            fieldOfStudy: 'CSE',
            startYear: 2022,
            endYear: 2026,
          ),
        ],
        skills: [
          ParsedSkill(name: 'Dart', category: 'Mobile Development', confidence: 1.0),
        ],
        domains: ['Mobile'],
        experienceLevel: 'student',
      );

      final json = profile.toJson();
      expect(json['education'], isA<List>());
      expect(json['skills'][0]['name'], 'Dart');
      expect(json['domains'], contains('Mobile'));
      expect(json['experience_level'], 'student');
    });
  });

  group('Intent Structuring & Confirmation Logic', () {
    final service = OnboardingService();

    test('structureIntentLocally detects roles, domains and help type from example text', () {
      const text = 'Looking for a data analyst internship at a fintech startup with mock interview guidance';
      final structured = service.structureIntentLocally(text, goalType: 'internship');

      expect(structured.goal, text);
      expect(structured.roles, contains('Data Analyst'));
      expect(structured.domains, contains('Fintech & Startups'));
      expect(structured.helpType, 'mock_interview');
    });

    test('structureIntentLocally defaults sensibly when free text is brief', () {
      const text = 'Need career guidance on MS abroad';
      final structured = service.structureIntentLocally(text);

      expect(structured.goal, text);
      expect(structured.domains, contains('Higher Studies'));
      expect(structured.helpType, 'career_guidance');
    });
  });
}
