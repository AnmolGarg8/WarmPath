import 'package:flutter/material.dart';
import 'package:warmpath_app/core/widgets/band_badge.dart';
import 'package:warmpath_app/core/widgets/w_card.dart';

class RatingsPage extends StatelessWidget {
  const RatingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rating & Band")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: WCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Your Current Band", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 12),
              BandBadge(band: "Rising"),
              SizedBox(height: 12),
              Text("Smoothed Rating: 4.0 / 5.0 (Bayesian prior applied)"),
            ],
          ),
        ),
      ),
    );
  }
}
