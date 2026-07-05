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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: EdgeColors.surface.withOpacity(0.94),
          border: const Border(
            top: BorderSide(color: EdgeColors.white06),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 4,
        ),
        child: SizedBox(
          height: kBottomNavHeight - 4,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 2),
            itemBuilder: (context, index) {
              final e = items[index];
              final active =
                  current == e.route || current.startsWith('${e.route}/');
              return _BottomTab(entry: e, active: active);
            },
          ),
        ),
      ),
    );
  }
}

/// Two-part active state matching the app's premium feel:
///   • a 22-px accent bar anchored to the top edge of the tab (like a
///     modern browser tab indicator), with a soft glow
///   • a subtle radial tint fading down behind the icon
/// Inactive tabs are colourless icon + label — nothing shouty.
class _BottomTab extends StatelessWidget {
  const _BottomTab({required this.entry, required this.active});
  final NavEntry entry;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(entry.route),
      borderRadius: BorderRadius.circular(14),
      splashColor: EdgeColors.accent.withOpacity(0.08),
      highlightColor: EdgeColors.accent.withOpacity(0.04),
      child: SizedBox(
        width: 78,
        child: Stack(
          children: [
            // Soft radial tint that only appears when active — grounds
            // the tab so the indicator bar doesn't float on its own.
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: active ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.6),
                      radius: 0.9,
                      colors: [
                        EdgeColors.accent.withOpacity(0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  height: 2.5,
                  width: active ? 22 : 0,
                  decoration: BoxDecoration(
                    color: EdgeColors.accent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: EdgeColors.accent.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: -1,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    entry.icon,
                    size: 20,
                    color:
                        active ? EdgeColors.accentHi : EdgeColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.sans(
                    size: 10.5,
                    color: active
                        ? Colors.white
                        : EdgeColors.muted,
                    weight: active ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
