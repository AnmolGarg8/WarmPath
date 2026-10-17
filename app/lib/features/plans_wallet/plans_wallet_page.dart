import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_card.dart';

class PlansWalletPage extends StatelessWidget {
  const PlansWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plans & Wallet')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: WCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Credit Balance & Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              SizedBox(height: 8),
              Text('Own-college alumni are free. Purchase subscription credits for cross-college access (test mode only).'),
            ],
          ),
        ),
      ),
    );
  }
}
