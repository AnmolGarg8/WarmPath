import 'package:flutter/material.dart';
import 'package:warmpath_app/core/widgets/w_card.dart';
import 'package:warmpath_app/core/widgets/w_button.dart';

class PlansWalletPage extends StatelessWidget {
  const PlansWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Plans & Credit Wallet")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const WCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your Wallet Balance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Text("0 Paid Credits (Cross-College)"),
                Text("0 Affinity Credits (Own-College)"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Standard Plan - ₹299/mo", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Includes 1 credit. Reach Rising mentors. 3-day booking horizon."),
                const SizedBox(height: 12),
                WButton(label: "Upgrade (Test Mode)", onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
