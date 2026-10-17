import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/w_card.dart';
import '../models/onboarding_models.dart';

class ProfileReviewStep extends StatefulWidget {
  final ParsedProfile initialProfile;
  final ValueChanged<ParsedProfile> onSaveProfile;
  final bool isSaving;

  const ProfileReviewStep({
    super.key,
    required this.initialProfile,
    required this.onSaveProfile,
    this.isSaving = false,
  });

  @override
  State<ProfileReviewStep> createState() => _ProfileReviewStepState();
}

class _ProfileReviewStepState extends State<ProfileReviewStep> {
  late ParsedProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
  }

  void _addSkillDialog() {
    final nameCtrl = TextEditingController();
    String category = 'Programming Languages';
    final categories = [
      'Programming Languages',
      'Web Frameworks',
      'Databases',
      'Cloud & DevOps',
      'AI/ML',
      'Mobile Development',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Technical Skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Skill Name (e.g. Flutter, PyTorch)'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => category = val);
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = nameCtrl.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _profile.skills.add(ParsedSkill(name: text, category: category, confidence: 1.0));
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _addDomainDialog() {
    final domainCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Domain'),
        content: TextField(
          controller: domainCtrl,
          decoration: const InputDecoration(labelText: 'Domain (e.g. Fintech, EdTech, Cloud)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = domainCtrl.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _profile.domains.add(text);
                });
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group skills by category
    final Map<String, List<ParsedSkill>> groupedSkills = {};
    for (final s in _profile.skills) {
      groupedSkills.putIfAbsent(s.category, () => []).add(s);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Obvious Student Control Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.12),
              borderRadius: AppRadii.card,
              border: Border.all(color: AppColors.teal.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: AppColors.teal, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are in full control: edit, add, or remove any item before matching. Nothing is hidden or used without your consent.',
                    style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Education Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Education',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              Text(
                '${_profile.education.length} entries',
                style: const TextStyle(fontSize: 12, color: AppColors.slate),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._profile.education.map((edu) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: WCard(
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, color: AppColors.deepIndigo, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${edu.degree} in ${edu.fieldOfStudy}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(edu.institution, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                          if (edu.startYear != null || edu.endYear != null)
                            Text(
                              '${edu.startYear ?? ''} - ${edu.endYear ?? 'Present'}',
                              style: const TextStyle(fontSize: 11, color: AppColors.slate),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.slate),
                      onPressed: () {
                        setState(() {
                          _profile.education.remove(edu);
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          // 2. Skills Section with Category Grouping & Low Confidence Highlights
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Technical Skills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              TextButton.icon(
                onPressed: _addSkillDialog,
                icon: const Icon(Icons.add, size: 16, color: AppColors.primaryAction),
                label: const Text('Add Skill', style: TextStyle(color: AppColors.primaryAction, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...groupedSkills.entries.map((entry) {
            final category = entry.key;
            final skills = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: WCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.deepIndigo),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: skills.map((skill) {
                        final isLowConfidence = skill.confidence < 0.7;
                        return Chip(
                          backgroundColor: isLowConfidence ? AppColors.amber.withOpacity(0.15) : AppColors.surface,
                          side: BorderSide(
                            color: isLowConfidence ? AppColors.amber : AppColors.slate.withOpacity(0.2),
                          ),
                          avatar: isLowConfidence
                              ? const Icon(Icons.help_outline, size: 14, color: AppColors.amber)
                              : null,
                          label: Text(
                            skill.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: isLowConfidence ? AppColors.amber : AppColors.textDark,
                              fontWeight: isLowConfidence ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setState(() {
                              _profile.skills.remove(skill);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // 3. Technical Domains
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Domains & Industries',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              TextButton.icon(
                onPressed: _addDomainDialog,
                icon: const Icon(Icons.add, size: 16, color: AppColors.primaryAction),
                label: const Text('Add Domain', style: TextStyle(color: AppColors.primaryAction, fontSize: 13)),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _profile.domains.map((dom) {
              return Chip(
                backgroundColor: AppColors.teal.withOpacity(0.1),
                side: BorderSide(color: AppColors.teal.withOpacity(0.3)),
                label: Text(dom, style: const TextStyle(fontSize: 12, color: AppColors.teal)),
                deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.teal),
                onDeleted: () {
                  setState(() {
                    _profile.domains.remove(dom);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 4. Projects Section
          const Text(
            'Highlighted Projects',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          ..._profile.projects.map((proj) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: WCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            proj.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.slate),
                          onPressed: () {
                            setState(() {
                              _profile.projects.remove(proj);
                            });
                          },
                        ),
                      ],
                    ),
                    Text(proj.description, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                    if (proj.tech.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: proj.tech.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(t, style: const TextStyle(fontSize: 10, color: AppColors.deepIndigo)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // 5. Experience Level Selector
          const Text(
            'Experience Level',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'student', label: Text('Student')),
              ButtonSegment(value: 'entry', label: Text('Entry')),
              ButtonSegment(value: 'mid', label: Text('Mid')),
              ButtonSegment(value: 'senior', label: Text('Senior')),
            ],
            selected: {_profile.experienceLevel},
            onSelectionChanged: (newSet) {
              setState(() {
                _profile.experienceLevel = newSet.first;
              });
            },
          ),
          const SizedBox(height: 32),

          // Save Action
          SizedBox(
            width: double.infinity,
            child: WButton(
              label: 'Save Profile & Set Career Intent',
              isLoading: widget.isSaving,
              onPressed: () => widget.onSaveProfile(_profile),
            ),
          ),
        ],
      ),
    );
  }
}
