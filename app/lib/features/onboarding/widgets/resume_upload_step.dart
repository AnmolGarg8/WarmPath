import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/w_card.dart';
import '../models/onboarding_models.dart';
import '../services/onboarding_service.dart';

class ResumeUploadStep extends StatefulWidget {
  final OnboardingService service;
  final ValueChanged<ParsedProfile> onProfileParsed;
  final VoidCallback onBackToConsent;

  const ResumeUploadStep({
    super.key,
    required this.service,
    required this.onProfileParsed,
    required this.onBackToConsent,
  });

  @override
  State<ResumeUploadStep> createState() => _ResumeUploadStepState();
}

enum UploadStatus { idle, uploading, parsing, error }

class _ResumeUploadStepState extends State<ResumeUploadStep> {
  UploadStatus _status = UploadStatus.idle;
  String? _selectedFileName;
  int? _selectedFileSize;
  double _uploadProgress = 0.0;
  String _statusMessage = '';
  String? _errorMessage;
  String? _errorCode;

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _setError('Unable to read selected file bytes.', null);
        return;
      }

      // Check max 5 MB
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        _setError('File size exceeds the 5 MB maximum limit. Please upload a smaller file.', 'file_too_large');
        return;
      }

      setState(() {
        _selectedFileName = file.name;
        _selectedFileSize = bytes.lengthInBytes;
        _status = UploadStatus.uploading;
        _uploadProgress = 0.3;
        _statusMessage = 'Uploading ${file.name}...';
        _errorMessage = null;
        _errorCode = null;
      });

      // 1. Upload file
      await widget.service.uploadResume(bytes, file.name);

      setState(() {
        _status = UploadStatus.parsing;
        _uploadProgress = 0.7;
        _statusMessage = 'Analyzing skills, education & projects with AI...';
      });

      // 2. Poll until parsed
      final parsedProfile = await widget.service.pollProfileUntilParsed();

      setState(() {
        _uploadProgress = 1.0;
        _status = UploadStatus.idle;
      });

      widget.onProfileParsed(parsedProfile);
    } on AppException catch (e) {
      _setError(e.message, e.code);
    } catch (e) {
      _setError('Failed to process resume: $e', 'upload_failed');
    }
  }

  Future<void> _demoAutoParse() async {
    setState(() {
      _selectedFileName = 'Anmol_Garg_Resume_VIPS.pdf';
      _status = UploadStatus.uploading;
      _uploadProgress = 0.35;
      _statusMessage = 'Uploading Anmol_Garg_Resume_VIPS.pdf...';
      _errorMessage = null;
      _errorCode = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _status = UploadStatus.parsing;
      _uploadProgress = 0.75;
      _statusMessage = 'Extracting skills, education & projects with Gemini AI...';
    });

    await Future.delayed(const Duration(milliseconds: 900));

    final demoProfile = await widget.service.getProfile();

    setState(() {
      _uploadProgress = 1.0;
      _status = UploadStatus.idle;
    });

    widget.onProfileParsed(demoProfile);
  }

  void _setError(String msg, String? code) {
    setState(() {
      _status = UploadStatus.error;
      _errorMessage = msg;
      _errorCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_status == UploadStatus.uploading || _status == UploadStatus.parsing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: WCard(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 48,
                  width: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primaryAction,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _status == UploadStatus.uploading ? 'Uploading Document' : 'Extracting Structured Profile',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.slate),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'All resume text is parsed inertly without executing directives.',
                  style: TextStyle(fontSize: 12, color: AppColors.slate, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_status == UploadStatus.error) {
      if (_errorCode == 'resume_unreadable') {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: WCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.document_scanner_outlined, size: 54, color: AppColors.primaryAction),
                  const SizedBox(height: 16),
                  const Text(
                    'Scanned Image Resume Detected',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your PDF appears to be an image-only scan without selectable text. Please export your resume directly as a PDF from Word, Google Docs, or Canva and try again.',
                    style: TextStyle(fontSize: 14, color: AppColors.slate),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  WButton(
                    label: 'Select Another Document',
                    onPressed: _pickAndUploadFile,
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (_errorCode == 'consent_required') {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: WCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock, size: 50, color: AppColors.amber),
                  const SizedBox(height: 16),
                  const Text(
                    'Consent Required',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'You must grant resume processing consent under DPDP Act.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.slate),
                  ),
                  const SizedBox(height: 20),
                  WButton(
                    label: 'Go to Consent Settings',
                    onPressed: widget.onBackToConsent,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return ErrorState(
        title: 'Upload Failed',
        message: _errorMessage ?? 'An error occurred while uploading. Please try again.',
        onRetry: _pickAndUploadFile,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Your Resume',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'We will extract your skills, technical domains, and projects. You will review and control everything before it is used.',
            style: TextStyle(fontSize: 14, color: AppColors.slate),
          ),
          const SizedBox(height: 28),
          WCard(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            onTap: _pickAndUploadFile,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.deepIndigo.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.upload_file, size: 48, color: AppColors.deepIndigo),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap to Select PDF or DOCX',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Supports PDF and DOCX up to 5 MB (max 5 pages)',
                  style: TextStyle(fontSize: 13, color: AppColors.slate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome, color: AppColors.teal),
              label: const Text(
                'Demo: Use Sample VIPS Resume (AI Extract)',
                style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.teal, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
              ),
              onPressed: _demoAutoParse,
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: AppColors.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your raw resume document is private and never exposed to anyone.',
                  style: TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
