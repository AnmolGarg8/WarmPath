import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/skeleton_box.dart';
import '../../core/widgets/main_bottom_nav.dart';
import 'controllers/pagination_controller.dart';
import 'services/discover_service.dart';
import 'widgets/giver_card.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final DiscoverService _service;

  late final PaginationController _ownCollegeController;
  late final PaginationController _crossCollegeController;
  late final PaginationController _expertsController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _service = DiscoverService();

    _ownCollegeController = PaginationController(service: _service, scope: 'own_college');
    _crossCollegeController = PaginationController(service: _service, scope: 'cross_college');
    _expertsController = PaginationController(service: _service, scope: 'experts');

    // Load initial data
    _ownCollegeController.loadInitial();
    _crossCollegeController.loadInitial();
    _expertsController.loadInitial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ownCollegeController.dispose();
    _crossCollegeController.dispose();
    _expertsController.dispose();
    super.dispose();
  }

  Widget _buildTabList(PaginationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading && controller.items.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: const [
              SkeletonBox(height: 160),
              SizedBox(height: 14),
              SkeletonBox(height: 160),
              SizedBox(height: 14),
              SkeletonBox(height: 160),
            ],
          );
        }

        if (controller.error != null && controller.items.isEmpty) {
          final isMissingResume = controller.error!.contains('profile_not_found') ||
              controller.error!.contains('intent_not_found') ||
              controller.error!.contains('student_verification_required');

          if (isMissingResume) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyState(
                      title: 'Add Your Resume to Get Matches',
                      message: 'Upload your resume and state your career intent to unlock personalized alumni recommendations.',
                      icon: Icons.upload_file_outlined,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAction,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => context.push('/onboarding'),
                      child: const Text('Start Onboarding', style: TextStyle(color: AppColors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ErrorState(
            title: 'Recommendations Unavailable',
            message: controller.error!,
            onRetry: () => controller.loadInitial(),
          );
        }

        if (controller.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyState(
                    title: 'No Matches Yet',
                    message: 'Add your resume to get matches from your alumni network.',
                    icon: Icons.people_outline,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAction,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => context.push('/onboarding'),
                    child: const Text('Upload Resume & Set Intent', style: TextStyle(color: AppColors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refresh(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: controller.items.length + (controller.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return GiverCard(item: controller.items[index]);
              },
            ),
          ),
        );
      },
    );
  }

  void _showDemoTourSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.slate.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.stars_rounded, color: AppColors.primaryAction, size: 28),
                SizedBox(width: 10),
                Text(
                  'WarmPath Live Demo Tour',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Experience the full prototype demonstration according to the team brief specification.',
              style: TextStyle(fontSize: 13, color: AppColors.slate),
            ),
            const Divider(height: 24),
            _buildTourItem(
              ctx,
              step: '1',
              title: 'Sign Up & Institutional Verification',
              desc: 'College email check against approved list, passwordless OTP, and graduated trust privileges.',
              icon: Icons.verified_user_outlined,
              color: AppColors.deepIndigo,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/auth/intro');
              },
            ),
            _buildTourItem(
              ctx,
              step: '2',
              title: 'DPDP Consent & Resume Parser',
              desc: 'India DPDP consent, AI resume parsing to skills, editable chips, and profile review.',
              icon: Icons.description_outlined,
              color: AppColors.teal,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/onboarding');
              },
            ),
            _buildTourItem(
              ctx,
              step: '3',
              title: 'State Career Intent ("What do you want next?")',
              desc: 'Explicit goal formulation matched against alumni offerings and expertise.',
              icon: Icons.lightbulb_outline,
              color: AppColors.amber,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/onboarding');
              },
            ),
            _buildTourItem(
              ctx,
              step: '4',
              title: 'AI Recommendations & Why-Lines',
              desc: 'Free same-college alumni (warm path), cross-college, and expert matches with heuristic why-fit explanation.',
              icon: Icons.explore_outlined,
              color: AppColors.primaryAction,
              onTap: () => Navigator.pop(ctx),
            ),
            _buildTourItem(
              ctx,
              step: '5',
              title: 'Connect & Instant / Booked Mentorship',
              desc: '72-hour reply guarantee, online presence detection, and capacity enforcement.',
              icon: Icons.flash_on_outlined,
              color: AppColors.deepIndigo,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/connect', extra: {
                  'giver_id': 'giver_mentor_01',
                  'giver_name': 'Verified Mentor',
                  'is_online_now': true,
                  'is_own_college': true,
                  'student_plan': 'Standard',
                  'prefilled_intent': 'Career mentorship and project review',
                });
              },
            ),
            _buildTourItem(
              ctx,
              step: '6',
              title: 'Live Video Call & Scam Detection Chat',
              desc: 'Integrated Jitsi session, min 5-min call duration rule, and scam warning banner.',
              icon: Icons.video_call_outlined,
              color: AppColors.teal,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/sessions');
              },
            ),
            _buildTourItem(
              ctx,
              step: '7',
              title: 'Session Rating & Bayesian Band Progression',
              desc: 'Mandatory 1-5 star rating, 48h dispute window, and Rising -> Trusted -> Top Rated bands.',
              icon: Icons.star_rate_outlined,
              color: AppColors.amber,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/ratings/band');
              },
            ),
            _buildTourItem(
              ctx,
              step: '8',
              title: 'Credit Economy & Razorpay Test Checkout',
              desc: 'Standard/High/Premium plans, credit ledger, giver cashout, and scholarship donation pool.',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.successGreen,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/plans-wallet');
              },
            ),
            _buildTourItem(
              ctx,
              step: '9',
              title: 'Trust & DPDP Data Privacy Controls',
              desc: 'Machine-readable JSON data export, DPDP account erasure, and graduated trust scoring.',
              icon: Icons.shield_outlined,
              color: AppColors.slate,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/profile');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourItem(
    BuildContext ctx, {
    required String step,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate.withOpacity(0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: AppColors.slate, height: 1.3),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.slate.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WarmPath Recommendations'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_filled, color: AppColors.primaryAction),
            tooltip: 'Live Demo Tour',
            onPressed: () => _showDemoTourSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Resume & Intent',
            onPressed: () => context.push('/onboarding'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryAction,
          unselectedLabelColor: AppColors.slate,
          indicatorColor: AppColors.primaryAction,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Own College (Free)'),
            Tab(text: 'Other Colleges'),
            Tab(text: 'Experts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabList(_ownCollegeController),
          _buildTabList(_crossCollegeController),
          _buildTabList(_expertsController),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }
}
