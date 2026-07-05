import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = EdgeColors.accent});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 1,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0)],
            ),
          ),
        ),
        Text(
          text.toUpperCase(),
          style: AppTheme.sans(
            size: 10.5,
            weight: FontWeight.w600,
            color: color,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }
}
