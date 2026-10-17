import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class BandBadge extends StatelessWidget {
  final String band; // 'Rising', 'Trusted', 'Top Rated'

  const BandBadge({super.key, required this.band});

  @override
  Widget build(BuildContext context) {
    Color bg;
    IconData icon;
    String label;

    switch (band.toLowerCase()) {
      case 'top rated':
      case 'top_rated':
        bg = AppColors.bandTopRated;
        icon = Icons.star;
        label = 'Top Rated';
        break;
      case 'trusted':
        bg = AppColors.bandTrusted;
        icon = Icons.verified;
        label = 'Trusted';
        break;
      case 'rising':
      default:
        bg = AppColors.bandRising;
        icon = Icons.trending_up;
        label = 'Rising';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.12),
        borderRadius: AppRadii.badge,
        border: Border.all(color: bg.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: bg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: bg,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
