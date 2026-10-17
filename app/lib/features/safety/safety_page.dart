import 'package:flutter/material.dart';
import 'package:warmpath_app/core/widgets/verified_badge.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trust & Safety")),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VerifiedBadge(label: "7-Layer Shield Active"),
            SizedBox(height: 12),
            Text("Your trust level is Verified"),
          ],
        ),
      ),
    );
  }
}
