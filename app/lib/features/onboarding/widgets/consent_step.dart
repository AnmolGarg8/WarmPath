import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/w_card.dart';
import '../models/onboarding_models.dart';

class ConsentStep extends StatefulWidget {
  final List<ConsentItem> consents;
  final ValueChanged<List<ConsentItem>> onConsentsConfirmed;
  final bool isLoading;

  const ConsentStep({
    super.key,
    required this.consents,
    required this.onConsentsConfirmed,
    this.isLoading = false,
  });

  @override
  State<ConsentStep> createState() => _ConsentStepState();
}

class _ConsentStepState extends State<ConsentStep> {
  late List<ConsentItem> _localConsents;

  @override
  void initState() {
    super.initState();
    _localConsents = List.from(widget.consents);
  }

  void _showDataProtectionInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.teal),
            SizedBox(width: 8),
            Text('Your Privacy & DPDP Rights'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Digital Personal Data Protection (DPDP) Act Compliance:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Explicit Consent: We process your resume solely for mentorship discovery. Your raw PDF is never made public or sold.',
              ),
              SizedBox(height: 8),
              Text(
                '2. Instant Deletion: You can withdraw consent anytime from your settings or delete your account. Withdrawing consent permanently halts processing and purges derived embeddings and parsed data.',
              ),
              SizedBox(height: 8),
              Text(
                '3. Student Control: You review, edit, or remove all parsed skills before any mentor sees your profile.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _localConsents.any((c) => c.purpose == 'resume_processing' && c.granted);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Protection & Privacy',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'WarmPath puts trust and privacy first. Choose what you consent to share before continuing.',
            style: TextStyle(fontSize: 14, color: AppColors.slate),
          ),
          const SizedBox(height: 20),
          ..._localConsents.map((consent) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: WCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consent.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            consent.description,
                            style: const TextStyle(fontSize: 13, color: AppColors.slate),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: consent.granted,
                      activeColor: AppColors.teal,
                      onChanged: (val) {
                        setState(() {
                          consent.granted = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: _showDataProtectionInfo,
              icon: const Icon(Icons.info_outline, size: 18, color: AppColors.teal),
              label: const Text(
                'How your data is protected & deleted under DPDP Act',
                style: TextStyle(color: AppColors.teal, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: WButton(
              label: 'Save Preferences & Continue',
              isLoading: widget.isLoading,
              onPressed: canProceed
                  ? () => widget.onConsentsConfirmed(_localConsents)
                  : null,
            ),
          ),
          if (!canProceed)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Please grant "Resume Processing" consent to upload your resume.',
                style: TextStyle(color: AppColors.primaryAction, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
