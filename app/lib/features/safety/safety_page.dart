import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_card.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trust & Safety')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: WCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Safety Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              SizedBox(height: 8),
              Text('Reports, trust score, and safety controls are managed here.'),
            ],
          ),
        ),
      ),
    );
  }
}
