import 'package:flutter/material.dart';
import 'package:warmpath_app/core/theme.dart';

class BandBadge extends StatelessWidget {
  final String band;

  const BandBadge({super.key, required this.band});

  @override
  Widget build(BuildContext context) {
    Color bg;
    IconData icon;
    String label = band;

    switch (band.toLowerCase()) {
      case 'top rated':
      case 'top_rated':
        bg = WarmPathColors.amber;
        icon = Icons.star;
        label = 'Top Rated';
        break;
      case 'trusted':
        bg = WarmPathColors.teal;
        icon = Icons.verified_user;
        label = 'Trusted';
        break;
      case 'rising':
      default:
        bg = WarmPathColors.slate;
        icon = Icons.trending_up;
        label = 'Rising';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: bg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: bg, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
