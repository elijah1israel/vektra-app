import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';

class UserMenu extends StatelessWidget {
  const UserMenu({super.key});

  String _initials(String? source) {
    final src = (source ?? '?').trim();
    final parts = src
        .split(RegExp(r'[\s@.]+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final a = parts.isNotEmpty ? parts[0][0] : '';
    final b = parts.length > 1 ? parts[1][0] : '';
    final s = (a + b).toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;
    final initials = _initials(user?.fullName ?? user?.email);
    return PopupMenuButton<String>(
      color: EdgeColors.card,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: EdgeColors.white10),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            width: 220,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: EdgeColors.white06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Trader',
                  style: AppTheme.sans(
                    size: 13,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: AppTheme.sans(size: 11.5, color: EdgeColors.muted),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: const [
              Icon(Icons.settings_outlined,
                  size: 16, color: EdgeColors.muted),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: const [
              Icon(Icons.logout, size: 16, color: EdgeColors.muted),
              SizedBox(width: 12),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      onSelected: (v) async {
        if (v == 'settings') {
          context.push('/settings');
        } else if (v == 'logout') {
          await context.read<AuthState>().logout();
          if (context.mounted) context.go('/login');
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: EdgeColors.accent,
              ),
              child: Text(
                initials,
                style: AppTheme.sans(
                  size: 12,
                  weight: FontWeight.w700,
                  color: EdgeColors.bg,
                ),
              ),
            ),
            const Icon(Icons.expand_more,
                size: 16, color: EdgeColors.muted),
          ],
        ),
      ),
    );
  }
}
