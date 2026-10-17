import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/skeleton_box.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WarmPath Recommendations'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
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
    );
  }
}
