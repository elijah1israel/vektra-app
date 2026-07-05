import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Glass card with the subtle gradient hairline border, matching the web
/// app. Pass `plain: true` to draw a single-color border instead of the
/// gradient — use it on danger sections and dense list rows where the
/// accent stop reads wrong.
class EdgeCard extends StatelessWidget {
  const EdgeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderColor,
    this.tint,
    this.borderRadius = 20,
    this.plain = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? tint;
  final double borderRadius;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    if (plain) {
      return Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: tint ?? EdgeColors.card.withOpacity(0.82),
          border: Border.all(
            color: borderColor ?? EdgeColors.white10,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xE6000000),
              blurRadius: 48,
              offset: Offset(0, 24),
              spreadRadius: -32,
            ),
          ],
        ),
        child: child,
      );
    }
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0xE6000000),
            blurRadius: 48,
            offset: Offset(0, 24),
            spreadRadius: -32,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    borderColor ?? Colors.white.withOpacity(0.14),
                    Colors.white.withOpacity(0.04),
                    EdgeColors.accent.withOpacity(0.12),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(1),
            padding: padding,
            decoration: BoxDecoration(
              color: tint ?? EdgeColors.card.withOpacity(0.82),
              borderRadius:
                  BorderRadius.circular(borderRadius - 1),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class SolidCard extends StatelessWidget {
  const SolidCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.background,
    this.borderRadius = 16,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? background;
  final double borderRadius;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: background ?? EdgeColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor ?? EdgeColors.white10),
        ),
        child: child,
      );
}
