import 'package:flutter/material.dart';
import 'package:warmpath_app/core/widgets/w_card.dart';
import 'package:warmpath_app/core/widgets/band_badge.dart';
import 'package:warmpath_app/core/widgets/verified_badge.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WarmPath Discover")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          WCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Top Recommendations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    BandBadge(band: "Top Rated"),
                  ],
                ),
                SizedBox(height: 8),
                Text("Matched by intent and verified alumnus history."),
                SizedBox(height: 8),
                VerifiedBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
