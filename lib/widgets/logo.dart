import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';

class VektraLogo extends StatelessWidget {
  const VektraLogo({super.key, this.size = 30, this.showText = true});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: EdgeColors.accent.withOpacity(0.45),
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.22),
            child: SvgPicture.asset(
              'assets/vektra-icon.svg',
              width: size,
              height: size,
              semanticsLabel: 'VektraPro',
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: AppTheme.display(
                size: size * 0.62,
                weight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              children: const [
                TextSpan(text: 'Vektra'),
                TextSpan(
                  text: 'Pro',
                  style: TextStyle(color: EdgeColors.accent),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
