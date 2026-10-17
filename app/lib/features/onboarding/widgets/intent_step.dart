import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/w_card.dart';
import '../models/onboarding_models.dart';
import '../services/onboarding_service.dart';

class IntentStep extends StatefulWidget {
  final OnboardingService service;
  final Function(String text, String? goalType, List<String> roles, List<String> domains) onConfirmAndSave;
  final bool isSaving;

  const IntentStep({
    super.key,
    required this.service,
    required this.onConfirmAndSave,
    this.isSaving = false,
  });

  @override
  State<IntentStep> createState() => _IntentStepState();
}

class _IntentStepState extends State<IntentStep> {
  final TextEditingController _intentCtrl = TextEditingController();
  String? _selectedGoalType;
  StructuredIntent? _previewIntent;

  final List<String> _exampleChips = [
    'Data Analyst Internship',
    'Startup in Fintech',
    'MS Abroad & Higher Studies',
    'Backend Software Engineering',
    'Mock Interview & Resume Review',
  ];

  final List<String> _goalTypes = [
    'internship',
    'job',
    'startup',
    'higher_studies',
    'guidance',
    'other',
  ];

  void _appendChipText(String text) {
    if (_intentCtrl.text.isEmpty) {
      _intentCtrl.text = text;
    } else {
      _intentCtrl.text = '${_intentCtrl.text.trim()}, $text';
    }
    setState(() {});
  }

  void _previewInterpretation() {
    final text = _intentCtrl.text.trim();
    if (text.isEmpty) return;

    final structured = widget.service.structureIntentLocally(text, goalType: _selectedGoalType);
    setState(() {
      _previewIntent = structured;
    });

    _showConfirmationModal(structured);
  }

  void _showConfirmationModal(StructuredIntent structured) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.teal, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Confirm Your Career Intent',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'We structured your request into these matching criteria. Please confirm before saving:',
              style: TextStyle(fontSize: 13, color: AppColors.slate),
            ),
            const SizedBox(height: 16),
            WCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Goal', structured.goal),
                  const Divider(height: 16),
                  _infoRow('Target Roles', structured.roles.join(', ')),
                  const Divider(height: 16),
                  _infoRow('Domains', structured.domains.join(', ')),
                  const Divider(height: 16),
                  _infoRow('Help Type Needed', structured.helpType.replaceAll('_', ' ')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
                    ),
                    child: const Text('Edit Text'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WButton(
                    label: 'Confirm & Match',
                    isLoading: widget.isSaving,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      widget.onConfirmAndSave(
                        _intentCtrl.text.trim(),
                        _selectedGoalType,
                        structured.roles,
                        structured.domains,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What do you want next?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'State your immediate career step or what guidance you need. We match you with verified alumni who walked that exact path.',
            style: TextStyle(fontSize: 14, color: AppColors.slate),
          ),
          const SizedBox(height: 20),

          // Example Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _exampleChips.map((chipText) {
              return ActionChip(
                backgroundColor: AppColors.white,
                side: BorderSide(color: AppColors.slate.withOpacity(0.3)),
                label: Text(chipText, style: const TextStyle(fontSize: 12, color: AppColors.deepIndigo)),
                avatar: const Icon(Icons.add, size: 14, color: AppColors.deepIndigo),
                onPressed: () => _appendChipText(chipText),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Free text input
          TextField(
            controller: _intentCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g. Looking for a summer backend SWE internship or mock interview preparation for product startups.',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: AppRadii.card,
                borderSide: BorderSide(color: AppColors.slate.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.card,
                borderSide: BorderSide(color: AppColors.slate.withOpacity(0.2)),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Goal Type Selector
          const Text(
            'Goal Type (Optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _goalTypes.map((type) {
              final isSelected = _selectedGoalType == type;
              return ChoiceChip(
                label: Text(type.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: AppColors.teal,
                onSelected: (val) {
                  setState(() {
                    _selectedGoalType = val ? type : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: WButton(
              label: 'Review Structured Intent',
              onPressed: _intentCtrl.text.trim().isNotEmpty ? _previewInterpretation : null,
            ),
          ),
        ],
      ),
    );
  }
}
