import 'package:flutter/material.dart';
import 'package:warmpath_app/core/widgets/w_card.dart';
import 'package:warmpath_app/core/widgets/w_button.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WarmPath Sign In")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: WCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter your institutional email to receive an OTP", textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: "College Email",
                    hintText: "student@college.edu",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                WButton(
                  label: "Send OTP",
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
