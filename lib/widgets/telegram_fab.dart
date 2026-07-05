import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../theme/colors.dart';
import 'app_shell.dart' show kBottomNavHeight;

/// Floating Telegram shortcut. Anchored above the bottom nav so it never
/// covers a tab — kBottomNavHeight is the strip's fixed height, plus the
/// system inset, plus a small gap.
class TelegramFab extends StatelessWidget {
  const TelegramFab({super.key});

  @override
  Widget build(BuildContext context) {
    final linked = context.select<AuthState, bool>(
        (a) => a.user?.telegramLinked ?? false);
    final dotColor = linked ? EdgeColors.accent : EdgeColors.warning;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Positioned(
      right: 18,
      bottom: kBottomNavHeight + bottomInset + 14,
      child: GestureDetector(
        onTap: () => context.push('/telegram'),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2AABEE), Color(0xFF229ED9)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF229ED9).withOpacity(0.55),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 24),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: Border.all(color: EdgeColors.bg, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
