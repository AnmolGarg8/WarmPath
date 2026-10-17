import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/band_badge.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/w_card.dart';
import '../models/discover_models.dart';
import '../services/discover_service.dart';

class GiverDetailPage extends StatefulWidget {
  final String giverId;

  const GiverDetailPage({super.key, required this.giverId});

  @override
  State<GiverDetailPage> createState() => _GiverDetailPageState();
}

class _GiverDetailPageState extends State<GiverDetailPage> {
  final DiscoverService _service = DiscoverService();
  GiverCardData? _giver;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGiver();
  }

  Future<void> _loadGiver() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getGiver(widget.giverId);
      if (mounted) {
        setState(() {
          _giver = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mentor Profile')),
        body: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              SkeletonBox(height: 120),
              SizedBox(height: 16),
              SkeletonBox(height: 200),
            ],
          ),
        ),
      );
    }

    if (_error != null || _giver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mentor Profile')),
        body: ErrorState(
          title: 'Profile Unavailable',
          message: _error ?? 'Unable to load mentor profile.',
          onRetry: _loadGiver,
        ),
      );
    }

    final giver = _giver!;

    return Scaffold(
      appBar: AppBar(
        title: Text(giver.fullName),
        backgroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            WCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.deepIndigo.withOpacity(0.1),
                        child: Text(
                          giver.fullName.isNotEmpty ? giver.fullName[0].toUpperCase() : 'M',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.deepIndigo),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              giver.fullName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            Text(giver.headline, style: const TextStyle(fontSize: 13, color: AppColors.slate)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const VerifiedBadge(role: 'Alumnus'),
                                const SizedBox(width: 8),
                                BandBadge(band: giver.band),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Rating & Availability Metrics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: AppColors.amber),
                              const SizedBox(width: 4),
                              Text(
                                giver.ratingSummary.smoothedAvg.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text('${giver.ratingSummary.totalSessions} sessions', style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                        ],
                      ),
                      Container(width: 1, height: 30, color: AppColors.slate.withOpacity(0.2)),
                      Column(
                        children: [
                          Text(
                            giver.availabilitySummary.online ? 'Online Now' : 'Offline',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: giver.availabilitySummary.online ? AppColors.successGreen : AppColors.slate,
                            ),
                          ),
                          Text('${giver.availabilitySummary.capacityLeft} slots this week', style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Why this mentor matches you (why_lines)
            if (giver.whyLines.isNotEmpty) ...[
              const Text('Why You Were Matched', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              WCard(
                child: Column(
                  children: giver.whyLines.map((line) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: AppColors.teal),
                          const SizedBox(width: 8),
                          Expanded(child: Text(line, style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bio
            if (giver.bio != null && giver.bio!.isNotEmpty) ...[
              const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 6),
              WCard(
                child: Text(giver.bio!, style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4)),
              ),
              const SizedBox(height: 16),
            ],

            // Offers
            if (giver.offers.isNotEmpty) ...[
              const Text('Mentorship Offerings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: giver.offers.map((offer) {
                  return Chip(
                    backgroundColor: AppColors.teal.withOpacity(0.1),
                    side: BorderSide(color: AppColors.teal.withOpacity(0.3)),
                    label: Text(offer.replaceAll('_', ' '), style: const TextStyle(fontSize: 12, color: AppColors.teal)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Skills & Topics
            if (giver.topics.isNotEmpty) ...[
              const Text('Discussion Topics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: giver.topics.map((t) => Chip(
                  backgroundColor: AppColors.surface,
                  label: Text(t, style: const TextStyle(fontSize: 11)),
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons: Connect and Book Slot
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.flash_on, color: AppColors.primaryAction),
                    label: const Text('Connect Now', style: TextStyle(color: AppColors.primaryAction)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryAction),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
                    ),
                    onPressed: () => context.push('/connect', extra: {
                      'giver_id': giver.id,
                      'giver_name': giver.fullName,
                      'is_online_now': giver.availabilitySummary.online,
                      'is_own_college': giver.isOwnCollege,
                      'student_plan': 'Standard',
                      'prefilled_intent': 'Career mentorship and project review',
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WButton(
                    label: 'Book Slot',
                    onPressed: () => context.push('/connect', extra: {
                      'giver_id': giver.id,
                      'giver_name': giver.fullName,
                      'is_online_now': false,
                      'is_own_college': giver.isOwnCollege,
                      'student_plan': 'Standard',
                      'prefilled_intent': 'Deep dive project architecture review',
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
