import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/w_card.dart';
import '../services/onboarding_service.dart';

class GiverProfileStep extends StatefulWidget {
  final OnboardingService service;

  const GiverProfileStep({super.key, required this.service});

  @override
  State<GiverProfileStep> createState() => _GiverProfileStepState();
}

class _GiverProfileStepState extends State<GiverProfileStep> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();

  final List<String> _availableOffers = [
    'resume_review',
    'mock_interview',
    'referral_advice',
    'career_guidance',
    'project_feedback',
    'domain_talk',
  ];
  final Set<String> _selectedOffers = {'resume_review', 'mock_interview'};

  final List<String> _topics = ['System Design', 'Frontend Architecture'];
  final List<String> _skills = ['Flutter', 'Python', 'PostgreSQL'];
  int _weeklyCapacity = 3;
  bool _isSaving = false;
  bool _isSaved = false;

  void _addTopic() {
    final t = _topicCtrl.text.trim();
    if (t.isNotEmpty && !_topics.contains(t)) {
      setState(() {
        _topics.add(t);
        _topicCtrl.clear();
      });
    }
  }

  void _addSkill() {
    final s = _skillCtrl.text.trim();
    if (s.isNotEmpty && !_skills.contains(s)) {
      setState(() {
        _skills.add(s);
        _skillCtrl.clear();
      });
    }
  }

  Future<void> _saveGiverProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOffers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one mentorship offer.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.service.saveGiverProfile({
        'offers': _selectedOffers.toList(),
        'topics': _topics,
        'skills': _skills.map((name) => {'name': name, 'category': 'Technical'}).toList(),
        'domains': ['Technology'],
        'company': _companyCtrl.text.trim(),
        'role_title': _roleCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'weekly_capacity': _weeklyCapacity,
      });

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giver profile saved successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mentor Profile Setup',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.12),
                    borderRadius: AppRadii.badge,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: AppColors.teal),
                      SizedBox(width: 4),
                      Text('Alumni Mentor', style: TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Specify how you can help students and what mentorship types you offer.',
              style: TextStyle(fontSize: 14, color: AppColors.slate),
            ),
            const SizedBox(height: 20),

            // 1. Mentorship Offers (Multi-select)
            const Text('Mentorship Offers (Select all that apply)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _availableOffers.map((offer) {
                final isSelected = _selectedOffers.contains(offer);
                final label = offer.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                return FilterChip(
                  label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.white : AppColors.textDark)),
                  selected: isSelected,
                  selectedColor: AppColors.primaryAction,
                  checkmarkColor: AppColors.white,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedOffers.add(offer);
                      } else {
                        _selectedOffers.remove(offer);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 2. Company & Role Title
            TextFormField(
              controller: _roleCtrl,
              decoration: const InputDecoration(
                labelText: 'Current Role Title *',
                hintText: 'e.g. Senior Software Engineer',
                filled: true,
                fillColor: AppColors.white,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Role title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _companyCtrl,
              decoration: const InputDecoration(
                labelText: 'Company / Organization *',
                hintText: 'e.g. Microsoft, Google, Zerodha',
                filled: true,
                fillColor: AppColors.white,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Company is required' : null,
            ),
            const SizedBox(height: 12),

            // 3. Bio
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mentorship Bio',
                hintText: 'Briefly describe your career journey and how you can support junior students.',
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 20),

            // 4. Topics
            const Text('Discussion Topics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _topicCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add topic (e.g. System Design)',
                      filled: true,
                      fillColor: AppColors.white,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addTopic(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTopic,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepIndigo),
                  child: const Text('Add', style: TextStyle(color: AppColors.white)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _topics.map((t) => Chip(
                label: Text(t, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => setState(() => _topics.remove(t)),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // 5. Weekly Capacity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Weekly Session Capacity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('$_weeklyCapacity sessions/wk', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryAction)),
              ],
            ),
            Slider(
              value: _weeklyCapacity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: AppColors.primaryAction,
              onChanged: (val) => setState(() => _weeklyCapacity = val.round()),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: WButton(
                label: 'Save Giver Profile',
                isLoading: _isSaving,
                onPressed: _saveGiverProfile,
              ),
            ),

            // 6. Availability Prompt
            const SizedBox(height: 28),
            WCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, color: AppColors.teal),
                      SizedBox(width: 8),
                      Text('Ready for Bookings?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Set your weekly availability schedule and real-time online status so students can request sessions.',
                    style: TextStyle(fontSize: 13, color: AppColors.slate),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule, color: AppColors.teal),
                      label: const Text('Set Availability & Slots', style: TextStyle(color: AppColors.teal)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.teal),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
                      ),
                      onPressed: () => context.push('/availability'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
