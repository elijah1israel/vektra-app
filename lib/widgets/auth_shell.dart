import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'ambient_background.dart';
import 'edge_card.dart';
import 'logo.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EdgeColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground(showGrid: true)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VektraLogo(size: 40),
                      const SizedBox(height: 28),
                      EdgeCard(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppTheme.display(
                                size: 24,
                                weight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: AppTheme.sans(
                                size: 13,
                                color: EdgeColors.muted,
                              ),
                            ),
                            const SizedBox(height: 22),
                            child,
                          ],
                        ),
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: 20),
                        DefaultTextStyle.merge(
                          textAlign: TextAlign.center,
                          style: AppTheme.sans(
                            size: 13,
                            color: EdgeColors.muted,
                          ),
                          child: footer!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InlineLink extends StatelessWidget {
  const InlineLink({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: AppTheme.sans(
          size: 13,
          weight: FontWeight.w600,
          color: EdgeColors.accent,
        ),
      ),
    );
  }
}
