import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_card.dart';

class RatingsPage extends StatelessWidget {
  const RatingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rating & Feedback')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: WCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Session Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              SizedBox(height: 8),
              Text('Submit two-way ratings and view your earned rating band (Rising, Trusted, Top Rated).'),
            ],
          ),
        ),
      ),
    );
  }
}
