import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/app_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/w_card.dart';
import '../auth_providers.dart';

class ProfileBasicsPage extends ConsumerStatefulWidget {
  const ProfileBasicsPage({super.key});

  @override
  ConsumerState<ProfileBasicsPage> createState() => _ProfileBasicsPageState();
}

class _ProfileBasicsPageState extends ConsumerState<ProfileBasicsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _headlineController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    if (user != null) {
      _nameController.text = user['display_name'] ?? user['full_name'] ?? '';
      _headlineController.text = user['headline'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).updateProfile(
            displayName: _nameController.text.trim(),
            headline: _headlineController.text.trim(),
          );

      if (mounted) {
        context.go('/profile');
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Failed to update profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Complete Your Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Basics',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell peers and alumni who you are. This information helps us match you with the right advisors.',
                  style: TextStyle(fontSize: 14, color: AppColors.slate, height: 1.4),
                ),
                const SizedBox(height: 24),
                WCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Display Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Anmol Garg',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.slate),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.button,
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadii.button,
                            borderSide: BorderSide(color: AppColors.primaryAction, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your display name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Headline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _headlineController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'e.g. B.Tech CSE \'25 | Aspiring Software Engineer',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.button,
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadii.button,
                            borderSide: BorderSide(color: AppColors.primaryAction, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a brief headline';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: AppRadii.card,
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 13, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: WButton(
                    label: 'Save & Go to Dashboard',
                    isLoading: _isLoading,
                    onPressed: _saveProfile,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
