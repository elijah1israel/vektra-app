import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';

class Spinner extends StatelessWidget {
  const Spinner({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        valueColor: AlwaysStoppedAnimation(color ?? Colors.white),
      ),
    );
  }
}

class PageSpinner extends StatelessWidget {
  const PageSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: EdgeColors.accent.withOpacity(0.2)),
                  ),
                ),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    valueColor: AlwaysStoppedAnimation(EdgeColors.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'LOADING',
              style: AppTheme.sans(
                size: 11,
                color: EdgeColors.muted,
                letterSpacing: 2.4,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
