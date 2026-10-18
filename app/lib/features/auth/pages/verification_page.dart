import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/app_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/w_card.dart';
import '../auth_providers.dart';

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({super.key});

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedKind = 'alumnus';
  final _evidenceTextController = TextEditingController();
  final _evidenceUrlsController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyRegController = TextEditingController();

  bool _isSubmitting = false;
  String? _formError;
  String? _successMessage;

  @override
  void dispose() {
    _evidenceTextController.dispose();
    _evidenceUrlsController.dispose();
    _companyNameController.dispose();
    _companyRegController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
      _successMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final urls = _evidenceUrlsController.text
          .split(',')
          .map((u) => u.trim())
          .where((u) => u.isNotEmpty)
          .toList();

      await repo.submitVerification(
        kind: _selectedKind,
        evidenceText: _evidenceTextController.text.trim(),
        evidenceUrls: urls.isNotEmpty ? urls : null,
        companyName: _companyNameController.text.trim().isNotEmpty
            ? _companyNameController.text.trim()
            : null,
        companyRegistration: _companyRegController.text.trim().isNotEmpty
            ? _companyRegController.text.trim()
            : null,
      );

      // Invalidate provider so it fetches fresh status
      ref.invalidate(verificationStatusProvider);
      ref.read(authStateProvider.notifier).checkAuth();

      setState(() {
        _successMessage =
            'Verification request submitted successfully! Our campus moderation team will review your evidence.';
        _evidenceTextController.clear();
        _evidenceUrlsController.clear();
        _companyNameController.clear();
        _companyRegController.clear();
      });
    } on AppException catch (e) {
      setState(() => _formError = e.message);
    } catch (_) {
      setState(() => _formError = 'Failed to submit verification request. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(verificationStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Campus Verification'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            statusAsync.when(
              data: (data) {
                final status = data['status'] ?? 'email_only';
                final level = data['verification_level'] ?? 'email_only';
                final badges = (data['badges'] as List?)?.map((b) => b.toString()).toList() ?? [];

                return WCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            level == 'verified'
                                ? Icons.verified_user_rounded
                                : Icons.pending_outlined,
                            color: level == 'verified' ? AppColors.teal : AppColors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${status.toString().toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        level == 'verified'
                            ? 'Your identity is verified. You have full access to peer and cross-campus advising.'
                            : 'You are currently logged in with email verification only. Submit evidence below to receive your verified role badge.',
                        style: const TextStyle(fontSize: 13, color: AppColors.slate, height: 1.4),
                      ),
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: badges.map((b) => VerifiedBadge(role: b)).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const WCard(
                child: Column(
                  children: [
                    SkeletonBox(width: double.infinity, height: 24),
                    SizedBox(height: 12),
                    SkeletonBox(width: double.infinity, height: 48),
                  ],
                ),
              ),
              error: (err, _) => ErrorState(
                message: 'Failed to load verification status',
                onRetry: () => ref.refresh(verificationStatusProvider),
              ),
            ),
            const SizedBox(height: 24),

            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.12),
                  borderRadius: AppRadii.card,
                  border: Border.all(color: AppColors.teal.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.teal, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Request Form Card
            WCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request Role Verification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Apply for verified alumnus, faculty, expert, or employer status by providing evidence.',
                      style: TextStyle(fontSize: 13, color: AppColors.slate),
                    ),
                    const SizedBox(height: 20),

                    // Role Selector
                    const Text(
                      'Verification Role',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedKind,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.button,
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'alumnus', child: Text('Alumnus / Graduate')),
                        DropdownMenuItem(value: 'faculty', child: Text('Faculty / Professor')),
                        DropdownMenuItem(value: 'expert', child: Text('Industry Expert / Mentor')),
                        DropdownMenuItem(value: 'employer', child: Text('Employer / Recruiter')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedKind = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Evidence Text
                    const Text(
                      'Evidence & Qualifications',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _evidenceTextController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Provide your graduation batch, degree, department, or university ID details...',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.button,
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide evidence text';
                        }
                        if (value.trim().length < 10) {
                          return 'Evidence text must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Evidence URLs
                    const Text(
                      'Evidence URLs (Optional, comma-separated)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _evidenceUrlsController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. https://linkedin.com/in/..., https://degree.cert/...',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.button,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Employer/Expert specific fields
                    if (_selectedKind == 'employer' || _selectedKind == 'expert') ...[
                      const Text(
                        'Company / Organization Name',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Acme Technologies Ltd.',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.button,
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if ((_selectedKind == 'employer') &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Company name is required for employer verification';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Company Registration / CIN / Tax ID (Optional)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _companyRegController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. CIN-U12345DL2020PTC123456',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.button,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_formError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: AppRadii.card,
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          _formError!,
                          style: const TextStyle(fontSize: 13, color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: WButton(
                        label: 'Submit for Campus Review',
                        isLoading: _isSubmitting,
                        onPressed: _submitRequest,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
