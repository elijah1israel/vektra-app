import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../theme/colors.dart';

class TelegramFab extends StatelessWidget {
  const TelegramFab({super.key});

  @override
  Widget build(BuildContext context) {
    final linked = context.select<AuthState, bool>(
        (a) => a.user?.telegramLinked ?? false);
    final dotColor = linked ? EdgeColors.accent : EdgeColors.warning;
    return Positioned(
      right: 20,
      bottom: 24,
      child: GestureDetector(
        onTap: () => context.push('/telegram'),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
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
                    color: const Color(0xFF229ED9).withOpacity(0.6),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 26),
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
