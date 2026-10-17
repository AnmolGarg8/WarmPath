import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import 'models/onboarding_models.dart';
import 'services/onboarding_service.dart';
import 'widgets/consent_step.dart';
import 'widgets/giver_profile_step.dart';
import 'widgets/intent_step.dart';
import 'widgets/profile_review_step.dart';
import 'widgets/resume_upload_step.dart';

enum OnboardingStep { consent, upload, review, intent, giverSetup }

class OnboardingPage extends StatefulWidget {
  final OnboardingStep initialStep;

  const OnboardingPage({
    super.key,
    this.initialStep = OnboardingStep.consent,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final OnboardingService _service;
  late OnboardingStep _currentStep;

  List<ConsentItem> _consents = [];
  ParsedProfile? _parsedProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _service = OnboardingService();
    _currentStep = widget.initialStep;
    _loadInitialConsents();
  }

  Future<void> _loadInitialConsents() async {
    setState(() => _isLoading = true);
    final consents = await _service.getConsents();
    if (mounted) {
      setState(() {
        _consents = consents;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConsentConfirmed(List<ConsentItem> consents) async {
    setState(() => _isLoading = true);
    try {
      await _service.saveConsents(consents);
      setState(() {
        _consents = consents;
        _isLoading = false;
        _currentStep = OnboardingStep.upload;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving consents: $e')),
        );
      }
    }
  }

  void _handleProfileParsed(ParsedProfile profile) {
    setState(() {
      _parsedProfile = profile;
      _currentStep = OnboardingStep.review;
    });
  }

  Future<void> _handleProfileSaved(ParsedProfile profile) async {
    setState(() => _isLoading = true);
    try {
      await _service.updateProfile(profile);
      setState(() {
        _parsedProfile = profile;
        _isLoading = false;
        _currentStep = OnboardingStep.intent;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  Future<void> _handleIntentSaved(
    String text,
    String? goalType,
    List<String> roles,
    List<String> domains,
  ) async {
    setState(() => _isLoading = true);
    try {
      await _service.saveIntent(
        text: text,
        goalType: goalType,
        targetRoles: roles,
        targetDomains: domains,
      );
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile & Intent saved! Recommendations ready.')),
        );
        // Navigate to discover recommendations
        context.go('/');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving intent: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: _currentStep != OnboardingStep.consent
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (_currentStep == OnboardingStep.upload) {
                      _currentStep = OnboardingStep.consent;
                    } else if (_currentStep == OnboardingStep.review) {
                      _currentStep = OnboardingStep.upload;
                    } else if (_currentStep == OnboardingStep.intent) {
                      _currentStep = OnboardingStep.review;
                    } else {
                      _currentStep = OnboardingStep.consent;
                    }
                  });
                },
              )
            : null,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = _currentStep == OnboardingStep.giverSetup
                    ? OnboardingStep.consent
                    : OnboardingStep.giverSetup;
              });
            },
            child: Text(
              _currentStep == OnboardingStep.giverSetup ? 'Student Onboarding' : 'Mentor Setup',
              style: const TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            if (_currentStep != OnboardingStep.giverSetup)
              LinearProgressIndicator(
                value: _progressValue,
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAction),
                minHeight: 4,
              ),
            Expanded(
              child: _buildCurrentStepWidget(),
            ),
          ],
        ),
      ),
    );
  }

  String get _stepTitle {
    switch (_currentStep) {
      case OnboardingStep.consent:
        return 'Step 1: Privacy & Consent';
      case OnboardingStep.upload:
        return 'Step 2: Resume Ingestion';
      case OnboardingStep.review:
        return 'Step 3: Review Profile';
      case OnboardingStep.intent:
        return 'Step 4: Career Intent';
      case OnboardingStep.giverSetup:
        return 'Alumni Mentor Setup';
    }
  }

  double get _progressValue {
    switch (_currentStep) {
      case OnboardingStep.consent:
        return 0.25;
      case OnboardingStep.upload:
        return 0.50;
      case OnboardingStep.review:
        return 0.75;
      case OnboardingStep.intent:
        return 1.0;
      case OnboardingStep.giverSetup:
        return 1.0;
    }
  }

  Widget _buildCurrentStepWidget() {
    if (_isLoading && _consents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentStep) {
      case OnboardingStep.consent:
        return ConsentStep(
          consents: _consents,
          isLoading: _isLoading,
          onConsentsConfirmed: _handleConsentConfirmed,
        );
      case OnboardingStep.upload:
        return ResumeUploadStep(
          service: _service,
          onProfileParsed: _handleProfileParsed,
          onBackToConsent: () => setState(() => _currentStep = OnboardingStep.consent),
        );
      case OnboardingStep.review:
        return ProfileReviewStep(
          initialProfile: _parsedProfile ?? ParsedProfile(),
          isSaving: _isLoading,
          onSaveProfile: _handleProfileSaved,
        );
      case OnboardingStep.intent:
        return IntentStep(
          service: _service,
          isSaving: _isLoading,
          onConfirmAndSave: _handleIntentSaved,
        );
      case OnboardingStep.giverSetup:
        return GiverProfileStep(service: _service);
    }
  }
}
