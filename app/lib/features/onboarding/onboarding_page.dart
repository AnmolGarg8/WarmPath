import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/skeleton_box.dart';
import '../../core/widgets/w_button.dart';
import '../../core/widgets/w_card.dart';
import 'onboarding_models.dart';
import 'onboarding_providers.dart';
import 'onboarding_service.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final TextEditingController _intentController = TextEditingController();
  bool _initializedIntent = false;

  @override
  void dispose() {
    _intentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(resumeProfileProvider);
    final intentAsync = ref.watch(studentIntentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume & Intent'),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _initializedIntent = false;
              ref.invalidate(resumeProfileProvider);
              ref.invalidate(studentIntentProvider);
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (error, _) {
          if (isNotImplemented(error)) {
            return const ErrorState(
              title: 'Feature Unavailable',
              message: 'This feature is not available yet',
            );
          }
          return ErrorState(
            title: 'Unable to Load Resume Data',
            message: error.toString(),
            onRetry: () {
              ref.invalidate(resumeProfileProvider);
              ref.invalidate(studentIntentProvider);
            },
          );
        },
        data: (ResumeProfile profile) {
          return intentAsync.when(
            loading: () => _buildLoadingSkeleton(),
            error: (error, _) {
              if (isNotImplemented(error)) {
                return const ErrorState(
                  title: 'Feature Unavailable',
                  message: 'This feature is not available yet',
                );
              }
              return ErrorState(
                title: 'Unable to Load Intent Data',
                message: error.toString(),
                onRetry: () => ref.invalidate(studentIntentProvider),
              );
            },
            data: (StudentIntent intent) {
              if (!_initializedIntent) {
                _intentController.text = intent.intent;
                _initializedIntent = true;
              }

              if (profile.skills.isEmpty && intent.intent.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const EmptyState(
                          title: 'No Resume Uploaded',
                          message: 'Upload your resume PDF to extract skills and state what you want next.',
                          icon: Icons.upload_file_outlined,
                        ),
                        const SizedBox(height: 20),
                        WButton(
                          label: 'Upload Resume PDF',
                          onPressed: () {
                            // File picker trigger
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  WCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parsed Skills',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (profile.skills.isEmpty)
                          const Text(
                            'No skills detected yet. Upload a fresh resume.',
                            style: TextStyle(fontSize: 13, color: AppColors.slate),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: profile.skills.map((s) {
                              return Chip(
                                label: Text(
                                  s.name,
                                  style: const TextStyle(fontSize: 12, color: AppColors.deepIndigo),
                                ),
                                backgroundColor: AppColors.surface,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  WCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What do you want next?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _intentController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'e.g. SDE-1 interview prep, resume critique, startup guidance...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: WButton(
                            label: 'Save Intent',
                            onPressed: () async {
                              final service = ref.read(onboardingServiceProvider);
                              await service.saveIntent(_intentController.text.trim());
                              ref.invalidate(studentIntentProvider);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        WCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 140, height: 20),
              SizedBox(height: 12),
              SkeletonBox(width: double.infinity, height: 16),
              SizedBox(height: 8),
              SkeletonBox(width: 220, height: 16),
              SizedBox(height: 16),
              SkeletonBox(width: 100, height: 36),
            ],
          ),
        ),
      ],
    );
  }
}
