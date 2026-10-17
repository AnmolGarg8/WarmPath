import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color color;
  final bool showLabel;
  final TextStyle? labelStyle;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 16.0,
    this.color = AppColors.amber,
    this.showLabel = true,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxRating, (index) {
            final starIndex = index + 1;
            if (rating >= starIndex) {
              return Icon(Icons.star, size: size, color: color);
            } else if (rating > index && rating < starIndex) {
              return Icon(Icons.star_half, size: size, color: color);
            } else {
              return Icon(Icons.star_border, size: size, color: color.withOpacity(0.5));
            }
          }),
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: labelStyle ??
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
          ),
        ],
      ],
    );
  }
}
