import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'ambient_background.dart';
import 'logo.dart';
import 'telegram_fab.dart';
import 'wallet_menu.dart';
import 'user_menu.dart';

class NavEntry {
  const NavEntry(this.route, this.label, this.icon);
  final String route;
  final String label;
  final IconData icon;
}

const _baseNav = <NavEntry>[
  NavEntry('/dashboard', 'Dashboard', Icons.dashboard_outlined),
  NavEntry('/instruments', 'Instruments', Icons.candlestick_chart_outlined),
  NavEntry('/discover', 'Discover', Icons.people_outline),
  NavEntry('/pricing', 'Pricing', Icons.credit_card_outlined),
  NavEntry('/telegram', 'Telegram', Icons.send),
  NavEntry('/settings', 'Settings', Icons.settings_outlined),
];

const _ownerNav = <NavEntry>[
  NavEntry('/plans', 'Plans', Icons.explore_outlined),
];

/// Height reserved above the system inset for the bottom nav strip. The
/// Telegram FAB anchors relative to this so it never overshadows a tab.
const kBottomNavHeight = 68.0;

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isOwner = auth.user?.isBotOwner ?? false;
    final items = [..._baseNav, if (isOwner) ..._ownerNav];
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: EdgeColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      kBottomNavHeight + 96,
                    ),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 900),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const TelegramFab(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomBar(items: items, current: currentRoute),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: EdgeColors.bg.withOpacity(0.7),
        border: const Border(
          bottom: BorderSide(color: EdgeColors.white06),
        ),
      ),
      child: Row(
        children: const [
          VektraLogo(size: 28),
          Spacer(),
          WalletMenu(),
          SizedBox(width: 6),
          UserMenu(),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.items, required this.current});
  final List<NavEntry> items;
  final String current;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EdgeColors.surface.withOpacity(0.94),
        border: const Border(
          top: BorderSide(color: EdgeColors.white06),
        ),
      ),
      padding: EdgeInsets.only(
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      child: SizedBox(
        height: kBottomNavHeight - 12,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final e = items[index];
            final active =
                current == e.route || current.startsWith('${e.route}/');
            return _BottomTab(entry: e, active: active);
          },
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({required this.entry, required this.active});
  final NavEntry entry;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? EdgeColors.accent : EdgeColors.muted;
    return InkWell(
      onTap: () => context.go(entry.route),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: active
              ? EdgeColors.accent.withOpacity(0.10)
              : Colors.transparent,
          border: Border.all(
            color: active
                ? EdgeColors.accent.withOpacity(0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(entry.icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              entry.label,
              style: AppTheme.sans(
                size: 12.5,
                color: color,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
