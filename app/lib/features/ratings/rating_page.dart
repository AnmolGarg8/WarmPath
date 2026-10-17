import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_card.dart';
import '../../core/widgets/w_button.dart';
import 'ratings_api_service.dart';
import 'ratings_controller.dart';

class RatingPage extends ConsumerStatefulWidget {
  final String sessionId;
  final bool isGiverRatingStudent;

  const RatingPage({
    super.key,
    required this.sessionId,
    this.isGiverRatingStudent = false,
  });

  @override
  ConsumerState<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends ConsumerState<RatingPage> {
  int _stars = 5;
  final TextEditingController _feedbackController = TextEditingController();
  final List<String> _availableTags = [
    'Helpful',
    'Actionable Advice',
    'Inspiring',
    'Deep Domain Knowledge',
    'Clear Communication',
    'Prepared & On Time',
  ];
  final Set<String> _selectedTags = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(ratingsApiServiceProvider);
      if (widget.isGiverRatingStudent) {
        await api.submitRequestQuality(
          sessionId: widget.sessionId,
          stars: _stars,
          note: _feedbackController.text.trim(),
        );
      } else {
        await api.submitRating(
          sessionId: widget.sessionId,
          stars: _stars,
          reason: _feedbackController.text.trim(),
          tags: _selectedTags.toList(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you! Your feedback has been recorded.')),
      );
      context.pop();
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGiverRatingStudent ? 'Rate Student Preparation' : 'Rate Your Mentorship Session'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          WCard(
            child: Column(
              children: [
                Text(
                  widget.isGiverRatingStudent
                      ? 'How prepared and clear was the student?'
                      : 'How valuable was this session with your mentor?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      iconSize: 40,
                      icon: Icon(
                        starIndex <= _stars ? Icons.star : Icons.star_border,
                        color: AppColors.amber,
                      ),
                      onPressed: () {
                        setState(() => _stars = starIndex);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_stars of 5 Stars',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!widget.isGiverRatingStudent) ...[
            WCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select tags that describe this session:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        selectedColor: AppColors.teal.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.teal : AppColors.textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          WCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isGiverRatingStudent ? 'Feedback Note (Private for admin & matching)' : 'Review / Notes (Helps future students):',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share key takeaways, specific insights, or constructive suggestions...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          WButton(
            label: 'Submit Feedback',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
