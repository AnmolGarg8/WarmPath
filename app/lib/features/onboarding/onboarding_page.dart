import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_button.dart';
import '../../core/widgets/w_card.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resume & Intent')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: WCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Upload Resume',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                const Text('Extract skills and state what you want next.', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                WButton(label: 'Select PDF', onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
