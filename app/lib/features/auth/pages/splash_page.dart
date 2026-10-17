import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/tokens.dart';
import '../auth_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    await Future.delayed(const Duration(milliseconds: 300)); // allow-delay: splash brand reveal animation
    if (!mounted) return;

    final token = await SecureStorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        await ref.read(authStateProvider.notifier).checkAuth();
        if (mounted) {
          final authState = ref.read(authStateProvider);
          if (authState.isAuthenticated) {
            context.go('/profile');
            return;
          }
        }
      } catch (_) {
        // Fall through to intro on check failure
      }
    }

    if (mounted) {
      context.go('/auth/intro');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hub_rounded, size: 72, color: AppColors.deepIndigo),
            SizedBox(height: 16),
            Text(
              'WarmPath',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Building a Network, Not a Directory',
              style: TextStyle(fontSize: 14, color: AppColors.slate),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAction),
          ],
        ),
      ),
    );
  }
}
