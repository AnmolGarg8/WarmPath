// allow-mock-file: guided demo, simulated and labelled
import '../models/demo_models.dart';
import 'finale/finale_chapter.dart';
import 'p1_matching/p1_matching_chapter.dart';
import 'p2_plans_credits/p2_plans_chapter.dart';
import 'p3_ratings/p3_ratings_chapter.dart';
import 'p4_trust/p4_trust_chapter.dart';
import 'p5_connect/p5_connect_chapter.dart';
import 'p6_institution/p6_institution_chapter.dart';

final List<DemoChapter> demoChaptersRegistry = [
  buildP1MatchingChapter(),
  buildP2PlansCreditsChapter(),
  buildP3RatingsChapter(),
  buildP4TrustChapter(),
  buildP5ConnectChapter(),
  buildP6InstitutionChapter(),
  buildFinaleChapter(),
];
