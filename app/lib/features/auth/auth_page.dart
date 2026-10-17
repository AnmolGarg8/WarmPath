import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_button.dart';
import '../../core/widgets/w_card.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WarmPath Auth')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: WCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Institutional Login',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                const Text('Enter your college email to receive an OTP.', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                WButton(label: 'Request OTP', onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
