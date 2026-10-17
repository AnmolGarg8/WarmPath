import 'package:flutter/material.dart';
import 'package:warmpath_app/core/widgets/w_card.dart';

class AvailabilityPage extends StatelessWidget {
  const AvailabilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Availability")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: WCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Weekly Capacity: 2 sessions max", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("Open Instant Window: Inactive"),
            ],
          ),
        ),
      ),
    );
  }
}
