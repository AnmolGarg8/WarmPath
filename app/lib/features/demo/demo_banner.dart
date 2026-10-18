// allow-mock-file: guided demo, simulated and labelled
import 'package:flutter/material.dart';

/// Permanent banner required on all guided demo screens to guarantee honesty.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  static const String bannerText =
      'DEMO MODE: simulated data and simulated payments. Nothing here is live.';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3CD), // High-visibility amber warning background
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF856404),
            size: 16,
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              bannerText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF856404),
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
