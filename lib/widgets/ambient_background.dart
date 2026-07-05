import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Layered ambient background — radial glows + optional grid — matching the
/// web app's aurora feel. Draw as the bottom-most layer under any screen.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, this.showGrid = false});
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: EdgeColors.bg),
            ),
          ),
          Positioned(
            top: -160,
            left: -60,
            child: _blob(
                size: 460,
                color: EdgeColors.accent.withOpacity(0.09)),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: _blob(
                size: 360, color: EdgeColors.info.withOpacity(0.05)),
          ),
          if (showGrid)
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
        ],
      ),
    );
  }

  Widget _blob({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 140, spreadRadius: 40),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94A3B8).withOpacity(0.05)
      ..strokeWidth = 1;
    const step = 56.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
