import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'eyebrow.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String? eyebrow;
  final Widget title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Eyebrow(eyebrow!),
          const SizedBox(height: 10),
        ],
        DefaultTextStyle.merge(
          style: AppTheme.display(
            size: 30,
            weight: FontWeight.w700,
            height: 1.1,
            letterSpacing: -0.6,
          ),
          child: title,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              subtitle!,
              style: AppTheme.sans(
                size: 13.5,
                color: EdgeColors.muted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );

    if (trailing == null) return head;
    return LayoutBuilder(builder: (ctx, box) {
      final tight = box.maxWidth < 480;
      if (tight) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            head,
            const SizedBox(height: 14),
            trailing!,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: head),
          const SizedBox(width: 12),
          trailing!,
        ],
      );
    });
  }
}
