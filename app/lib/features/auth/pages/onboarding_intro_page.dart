import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_button.dart';

class OnboardingIntroPage extends StatefulWidget {
  const OnboardingIntroPage({super.key});

  @override
  State<OnboardingIntroPage> createState() => _OnboardingIntroPageState();
}

class _OnboardingIntroPageState extends State<OnboardingIntroPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Find the Right People',
      'subtitle':
          'Match with verified alumni, faculty, founders, and experts from your institution based on real expertise and mutual intent.',
      'icon': Icons.people_alt_rounded,
      'color': AppColors.deepIndigo,
    },
    {
      'title': 'Help is Worth Their Time',
      'subtitle':
          'Givers define their weekly capacity and earn for their time. Connect for focused 20-minute sessions with zero spam.',
      'icon': Icons.access_time_filled_rounded,
      'color': AppColors.teal,
    },
    {
      'title': 'Rated & Protected Connections',
      'subtitle':
          'Institutional verification at entry, automated scam screening, escrow credits, and ratings after every single connection.',
      'icon': Icons.verified_user_rounded,
      'color': AppColors.primaryAction,
    },
  ];

  void _onNext() {
    if (_currentIndex < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/auth/email');
    }
  }

  void _onSkip() {
    context.go('/auth/email');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentIndex < _slides.length - 1)
            TextButton(
              onPressed: _onSkip,
              child: const Text(
                'Skip',
                style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: (slide['color'] as Color).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 60,
                            color: slide['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide['title'] as String,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.slate,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppColors.primaryAction
                        : AppColors.slate.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: WButton(
                  label: _currentIndex == _slides.length - 1 ? 'Get Started' : 'Next',
                  onPressed: _onNext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
