import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/api/app_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/main_bottom_nav.dart';
import '../../../core/widgets/trust_notice.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/w_card.dart';
import '../auth_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isExporting = false;
  bool _isDeleting = false;

  Future<void> _handleDataExport() async {
    setState(() => _isExporting = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final exportData = await repo.exportData();
      final prettyJson = const JsonEncoder.withIndent('  ').convert(exportData);

      await Share.share(
        prettyJson,
        subject: 'WarmPath_Data_Export.json',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal data export prepared successfully.')),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.message}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export data.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Your Account?'),
        content: const Text(
          'This action is irreversible under the Digital Personal Data Protection (DPDP) Act. '
          'Your profile, resume, and credentials will be permanently erased. '
          'Any platform records required for compliance will be completely anonymised.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slate)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isDeleting = true);
              try {
                await ref.read(authStateProvider.notifier).deleteAccount();
                if (mounted) {
                  context.go('/auth/email');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isDeleting = false);
                }
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) {
      context.go('/auth/email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    // Show clean loading state while user profile is loading
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('Profile & Settings'),
          backgroundColor: AppColors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAction),
        ),
        bottomNavigationBar: const MainBottomNav(currentIndex: 3),
      );
    }

    final displayName = user['display_name'] ?? user['full_name'] ?? 'WarmPath Member';
    final email = user['email'] ?? '';
    final headline = user['headline'] ?? 'Campus Member';
    final badges = (user['badges'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final trustLevel = user['trust_level'] ?? 'new';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.slate),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            WCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.deepIndigo.withOpacity(0.12),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepIndigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 13, color: AppColors.slate),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          headline,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.deepIndigo,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Badges Section
            WCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Campus Badges & Roles',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (badges.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: badges.map((b) => VerifiedBadge(role: b)).toList(),
                    ),
                  ] else ...[
                    const Text(
                      'No verified badges yet. Submit credentials to unlock your verified badge.',
                      style: TextStyle(fontSize: 13, color: AppColors.slate),
                    ),
                  ],
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
                    ),
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('Manage Verification & Badges'),
                    onPressed: () => context.go('/verification'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Trust Notice
            TrustNotice(
              title: 'Trust Level: ${trustLevel.toUpperCase()}',
              message:
                  'Every connection on WarmPath is verified and rating-protected. '
                  'Your private trust status governs daily request limits.',
              action: TextButton(
                onPressed: () => context.go('/safety/why-limited'),
                child: const Text(
                  'Why am I limited? View Safety Policy →',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings & Actions
            WCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.slideshow_rounded, color: AppColors.deepIndigo),
                    title: const Text('Guided Demo Walkthrough', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Simulated honest tour of all six WarmPath pillars'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.slate),
                    onTap: () => context.go('/demo'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: AppColors.deepIndigo),
                    title: const Text('Safety & Why am I limited?'),
                    subtitle: const Text('Understand trust rules and community safeguards'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.slate),
                    onTap: () => context.go('/safety/why-limited'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.teal),
                    title: const Text('Privacy & Consent Preferences'),
                    subtitle: const Text('Manage resume parsing and profile consent'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.slate),
                    onTap: () => context.go('/onboarding'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.download_outlined, color: AppColors.primaryAction),
                    title: const Text('Download My Data (DPDP Export)'),
                    subtitle: const Text('Save or share a complete copy of your personal data'),
                    trailing: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right, color: AppColors.slate),
                    onTap: _isExporting ? null : _handleDataExport,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                    title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Permanently remove your account and data'),
                    trailing: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: _isDeleting ? null : _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }
}
