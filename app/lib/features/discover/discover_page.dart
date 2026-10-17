import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/band_badge.dart';
import '../../core/widgets/verified_badge.dart';
import '../../core/widgets/w_card.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WarmPath Recommendations'),
        backgroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          WCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VerifiedBadge(role: 'Alumnus'),
                    SizedBox(width: 8),
                    BandBadge(band: 'Top Rated'),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Recommended Mentor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                SizedBox(height: 4),
                Text(
                  'Why this person: Same college + React & Node expertise match.',
                  style: TextStyle(fontSize: 13, color: AppColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
