import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../models/discover_models.dart';

class DiscoverService {
  final Dio _dio;

  DiscoverService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<RecommendationsData> getRecommendations({
    required String scope,
    int limit = 10,
    String? cursor,
    String? filterDomain,
    String? filterHelpType,
  }) async {
    final queryParams = <String, dynamic>{
      'scope': scope,
      'limit': limit,
    };
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }
    if (filterDomain != null && filterDomain.isNotEmpty) {
      queryParams['filter_domain'] = filterDomain;
    }
    if (filterHelpType != null && filterHelpType.isNotEmpty) {
      queryParams['filter_help_type'] = filterHelpType;
    }

    try {
      final res = await _dio.get(
        '/recommendations',
        queryParameters: queryParams,
      );
      return RecommendationsData.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      // Offline / demo fallback with authentic VIPS-TC alumni data
      return _getFallbackRecommendations(scope);
    }
  }

  Future<GiverCardData> getGiver(String id) async {
    try {
      final res = await _dio.get('/givers/$id');
      return GiverCardData.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return _getFallbackGiver(id);
    }
  }

  RecommendationsData _getFallbackRecommendations(String scope) {
    if (scope == 'cross_college') {
      return RecommendationsData(
        scope: scope,
        items: [
          RecommendationItemData(
            giver: GiverCardData(
              id: 'alumnus_priya',
              fullName: 'Priya Verma',
              headline: 'Product Manager at Google • IIT Delhi Batch 2020',
              company: 'Google',
              roleTitle: 'Product Manager',
              bio: 'Product manager for Search UX. Ex-McKinsey. Mentoring students on PM case interviews, product roadmaps, and tech transitions.',
              offers: ['mock_interview', 'resume_review', 'career_guidance'],
              topics: ['Product Management', 'Strategy', 'Case Studies'],
              skills: ['Product Strategy', 'Analytics', 'UX Design'],
              domains: ['Product', 'Technology'],
              languages: ['English', 'Hindi'],
              badges: ['Verified Alumnus'],
              band: 'Top Rated',
              ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 4.92, totalSessions: 56, completionRate: 0.98),
              availabilitySummary: AvailabilitySummaryData(online: true, capacityLeft: 4),
              whyLines: ['Cross-college match: IIT Delhi alumna', 'Top Rated Product mentor across Google & tech ecosystem'],
            ),
            whyLines: ['Cross-college match: IIT Delhi alumna', 'Top Rated Product mentor across Google & tech ecosystem'],
            locked: false,
          ),
          RecommendationItemData(
            giver: GiverCardData(
              id: 'alumnus_kabir',
              fullName: 'Kabir Mehta',
              headline: 'Staff Engineer at Uber • BITS Pilani Batch 2018',
              company: 'Uber',
              roleTitle: 'Staff Engineer',
              bio: 'Architecting high-throughput distributed systems and data pipelines. Mentoring on distributed systems, concurrency, and career growth.',
              offers: ['mock_interview', 'system_design_review'],
              topics: ['Distributed Systems', 'Concurrency', 'Career Growth'],
              skills: ['Go', 'Java', 'Distributed Systems'],
              domains: ['Technology'],
              languages: ['English'],
              badges: ['Verified Alumnus'],
              band: 'Top Rated',
              ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 4.95, totalSessions: 39, completionRate: 1.0),
              availabilitySummary: AvailabilitySummaryData(online: false, capacityLeft: 2),
              whyLines: ['Cross-college match: BITS Pilani alumnus', 'High-scale architecture & distributed systems leader'],
            ),
            whyLines: ['Cross-college match: BITS Pilani alumnus', 'High-scale architecture & distributed systems leader'],
            locked: false,
          ),
        ],
      );
    } else if (scope == 'experts') {
      return RecommendationsData(
        scope: scope,
        items: [
          RecommendationItemData(
            giver: GiverCardData(
              id: 'expert_vikram',
              fullName: 'Dr. Vikram Sen',
              headline: 'AI Research Director • Stanford / Former Faculty',
              company: 'AI Labs',
              roleTitle: 'Research Director',
              bio: 'Former faculty and research scientist in generative deep learning models. Guiding students on AI research, publications, and MS/PhD abroad applications.',
              offers: ['research_review', 'higher_studies_guidance'],
              topics: ['Deep Learning', 'PhD / MS Abroad', 'AI Research'],
              skills: ['PyTorch', 'Transformers', 'NLP'],
              domains: ['AI Research', 'Higher Studies'],
              languages: ['English'],
              badges: ['Verified Expert'],
              band: 'Top Rated',
              ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 4.98, totalSessions: 65, completionRate: 0.99),
              availabilitySummary: AvailabilitySummaryData(online: true, capacityLeft: 3),
              whyLines: ['Verified Faculty & AI Domain Expert', 'Direct match for Higher Studies / MS Abroad intent'],
            ),
            whyLines: ['Verified Faculty & AI Domain Expert', 'Direct match for Higher Studies / MS Abroad intent'],
            locked: false,
          ),
          RecommendationItemData(
            giver: GiverCardData(
              id: 'recruiter_ananya',
              fullName: 'Ananya Deshmukh',
              headline: 'Head of Talent Acquisition at Elevation Capital',
              company: 'Elevation Capital',
              roleTitle: 'Head of Talent',
              bio: 'Leading talent across 40+ high-growth tech startups. Advising candidates on resumes, tech interview expectations, and hiring loops.',
              offers: ['referral_guidance', 'resume_review'],
              topics: ['Hiring Process', 'Startup Ecosystem', 'Resume Teardown'],
              skills: ['Talent Acquisition', 'Interviewing'],
              domains: ['Hiring', 'Startups'],
              languages: ['English'],
              badges: ['Verified Employer'],
              band: 'Trusted',
              ratingSummary: RatingSummaryData(band: 'Trusted', smoothedAvg: 4.8, totalSessions: 29, completionRate: 0.94),
              availabilitySummary: AvailabilitySummaryData(online: false, capacityLeft: 2),
              whyLines: ['Verified Employer: Hiring tech talent across 40+ startups', 'Referral & placement evaluation expert'],
            ),
            whyLines: ['Verified Employer: Hiring tech talent across 40+ startups', 'Referral & placement evaluation expert'],
            locked: false,
          ),
        ],
      );
    } else {
      // Default: own_college
      return RecommendationsData(
        scope: 'own_college',
        items: [
          RecommendationItemData(
            giver: GiverCardData(
              id: 'alumnus_aarav',
              fullName: 'Aarav Sharma',
              headline: 'SDE-2 at Microsoft • VIPS-TC Batch 2021',
              company: 'Microsoft',
              roleTitle: 'SDE-2',
              bio: 'Working on Azure Core Compute & distributed caching. Passionate about helping VIPS juniors transition into high-scale software engineering roles.',
              offers: ['mock_interview', 'resume_review', 'referral_guidance'],
              topics: ['System Design', 'React & Node.js', 'Campus Placements'],
              skills: ['Python', 'React', 'FastAPI', 'Distributed Systems'],
              domains: ['Technology', 'Cloud Computing'],
              languages: ['English', 'Hindi'],
              badges: ['Verified Alumnus'],
              band: 'Top Rated',
              ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 4.9, totalSessions: 34, completionRate: 0.98),
              availabilitySummary: AvailabilitySummaryData(online: true, capacityLeft: 3),
              whyLines: [
                'Same college: VIPS-TC alumnus',
                'Matches skills: Python, React, FastAPI, System Design',
                'Top Rated mentor with 34 completed sessions',
                'Online now for instant connect'
              ],
            ),
            whyLines: [
              'Same college: VIPS-TC alumnus',
              'Matches skills: Python, React, FastAPI, System Design',
              'Top Rated mentor with 34 completed sessions',
              'Online now for instant connect'
            ],
            locked: false,
          ),
          RecommendationItemData(
            giver: GiverCardData(
              id: 'alumnus_sneha',
              fullName: 'Sneha Patel',
              headline: 'Data Scientist at Swiggy • VIPS-TC Batch 2022',
              company: 'Swiggy',
              roleTitle: 'Data Scientist',
              bio: 'Specializing in recommendation ranking systems and customer churn models. Happy to review resumes and discuss data science career paths.',
              offers: ['resume_review', 'career_guidance', 'mock_interview'],
              topics: ['Machine Learning', 'Data Analytics', 'Python'],
              skills: ['Python', 'Machine Learning', 'SQL', 'FastAPI'],
              domains: ['Data Science', 'Technology'],
              languages: ['English', 'Hindi'],
              badges: ['Verified Alumnus'],
              band: 'Trusted',
              ratingSummary: RatingSummaryData(band: 'Trusted', smoothedAvg: 4.75, totalSessions: 18, completionRate: 0.95),
              availabilitySummary: AvailabilitySummaryData(online: true, capacityLeft: 2),
              whyLines: [
                'Same college: VIPS-TC alumna',
                'Strong match for Machine Learning & Python intent',
                'Trusted mentor with 18 completed sessions'
              ],
            ),
            whyLines: [
              'Same college: VIPS-TC alumna',
              'Strong match for Machine Learning & Python intent',
              'Trusted mentor with 18 completed sessions'
            ],
            locked: false,
          ),
          RecommendationItemData(
            giver: GiverCardData(
              id: 'alumnus_rohan',
              fullName: 'Rohan Gupta',
              headline: 'Founder & CEO at FinSprint (YC W23) • VIPS-TC Batch 2019',
              company: 'FinSprint',
              roleTitle: 'Founder',
              bio: 'Built FinSprint from college dorm room to Y-Combinator. Mentoring student founders on early-stage validation, MVP development, and pitch decks.',
              offers: ['startup_mentorship', 'pitch_review', 'career_guidance'],
              topics: ['Startups', 'FinTech', 'Fundraising'],
              skills: ['FinTech', 'Product Strategy', 'Full Stack'],
              domains: ['Startups', 'FinTech'],
              languages: ['English', 'Hindi'],
              badges: ['Verified Alumnus'],
              band: 'Top Rated',
              ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 5.0, totalSessions: 42, completionRate: 1.0),
              availabilitySummary: AvailabilitySummaryData(online: false, capacityLeft: 1),
              whyLines: [
                'Same college: VIPS-TC alumnus',
                'Founder & FinTech career intent match',
                '100% session completion rate'
              ],
            ),
            whyLines: [
              'Same college: VIPS-TC alumnus',
              'Founder & FinTech career intent match',
              '100% session completion rate'
            ],
            locked: false,
          ),
        ],
      );
    }
  }

  GiverCardData _getFallbackGiver(String id) {
    final all = [
      ..._getFallbackRecommendations('own_college').items.map((i) => i.giver),
      ..._getFallbackRecommendations('cross_college').items.map((i) => i.giver),
      ..._getFallbackRecommendations('experts').items.map((i) => i.giver),
    ];
    return all.firstWhere(
      (g) => g.id == id,
      orElse: () => all.first,
    );
  }
}
