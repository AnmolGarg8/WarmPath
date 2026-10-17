import 'package:flutter/material.dart';
import 'package:warmpath_app/core/widgets/w_button.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Build Your Profile")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Upload your resume to extract skills with AI", textAlign: TextAlign.center),
              const SizedBox(height: 24),
              WButton(
                label: "Select Resume PDF",
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
