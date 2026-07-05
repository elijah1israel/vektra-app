import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'spinner.dart';

enum EdgeButtonKind { primary, ghost, outline, danger }
enum EdgeButtonSize { normal, large }

class EdgeButton extends StatelessWidget {
  const EdgeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = EdgeButtonKind.primary,
    this.size = EdgeButtonSize.normal,
    this.icon,
    this.trailing,
    this.busy = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final EdgeButtonKind kind;
  final EdgeButtonSize size;
  final IconData? icon;
  final IconData? trailing;
  final bool busy;
  final bool fullWidth;

  bool get _enabled => onPressed != null && !busy;

  @override
  Widget build(BuildContext context) {
    final radius = size == EdgeButtonSize.large ? 18.0 : 14.0;
    final padH = size == EdgeButtonSize.large ? 20.0 : 16.0;
    final padV = size == EdgeButtonSize.large ? 14.0 : 12.0;
    // Fix the content height so the button doesn't jump between
    // text-line-height and spinner-height when toggling busy.
    final contentHeight = size == EdgeButtonSize.large ? 22.0 : 20.0;
    final fg = _foreground();

    final children = busy
        ? [
            Spinner(size: 18, color: fg),
          ]
        : <Widget>[
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sans(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Icon(trailing, size: 16, color: fg),
            ],
          ];

    Widget button = InkWell(
      onTap: _enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: _decoration(radius),
        child: SizedBox(
          height: contentHeight,
          child: Row(
            mainAxisSize:
                fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }
    return Opacity(opacity: _enabled ? 1 : 0.55, child: button);
  }

  Color _foreground() {
    switch (kind) {
      case EdgeButtonKind.primary:
        return EdgeColors.bg;
      case EdgeButtonKind.ghost:
        return Colors.white;
      case EdgeButtonKind.outline:
        return EdgeColors.slate200;
      case EdgeButtonKind.danger:
        return EdgeColors.danger;
    }
  }

  BoxDecoration _decoration(double radius) {
    switch (kind) {
      case EdgeButtonKind.primary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF34D399),
              Color(0xFF10B981),
              Color(0xFF0EA371),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: EdgeColors.accent.withOpacity(0.35),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        );
      case EdgeButtonKind.ghost:
        return BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        );
      case EdgeButtonKind.outline:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: EdgeColors.border),
        );
      case EdgeButtonKind.danger:
        return BoxDecoration(
          color: EdgeColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: EdgeColors.danger.withOpacity(0.3),
          ),
        );
    }
  }
}
