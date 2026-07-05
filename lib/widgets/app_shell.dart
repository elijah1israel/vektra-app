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

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isOwner = auth.user?.isBotOwner ?? false;
    final items = [..._baseNav, if (isOwner) ..._ownerNav];
    final currentRoute =
        GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: EdgeColors.bg,
      drawer: _MobileDrawer(items: items),
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            child: Column(
              children: [
                _TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: child,
                    ),
                  ),
                ),
                _MobileNavBar(items: items, current: currentRoute),
              ],
            ),
          ),
          const TelegramFab(),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: EdgeColors.bg.withOpacity(0.7),
        border: const Border(
          bottom: BorderSide(color: EdgeColors.white06),
        ),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              icon: const Icon(Icons.menu, color: Colors.white),
              splashRadius: 20,
            ),
          ),
          const SizedBox(width: 4),
          const VektraLogo(size: 26),
          const Spacer(),
          const WalletMenu(),
          const SizedBox(width: 6),
          const UserMenu(),
        ],
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({required this.items});
  final List<NavEntry> items;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: EdgeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: const VektraLogo(size: 30),
            ),
            const Divider(color: EdgeColors.white08, height: 1),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'MENU',
                style: AppTheme.sans(
                  size: 10,
                  color: EdgeColors.muted,
                  letterSpacing: 2.4,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                children: items
                    .map((e) => _NavTile(entry: e))
                    .toList(growable: false),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: EdgeColors.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Signal engine online',
                    style: AppTheme.sans(
                      size: 11,
                      color: EdgeColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.entry});
  final NavEntry entry;

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).uri.toString();
    final active = current == entry.route ||
        current.startsWith('${entry.route}/');
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).maybePop();
        context.go(entry.route);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: active
              ? LinearGradient(
                  colors: [
                    EdgeColors.accent.withOpacity(0.14),
                    Colors.transparent,
                  ],
                )
              : null,
        ),
        child: Row(
          children: [
            if (active)
              Container(
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: EdgeColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(width: 13),
            Icon(entry.icon,
                size: 18,
                color:
                    active ? EdgeColors.accent : EdgeColors.muted),
            const SizedBox(width: 12),
            Text(
              entry.label,
              style: AppTheme.sans(
                size: 13.5,
                color: active ? Colors.white : EdgeColors.slate300,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavBar extends StatelessWidget {
  const _MobileNavBar({required this.items, required this.current});
  final List<NavEntry> items;
  final String current;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: EdgeColors.surface.withOpacity(0.92),
        border: const Border(
          top: BorderSide(color: EdgeColors.white06),
        ),
      ),
      padding: EdgeInsets.only(
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final e in visible)
            _BottomTab(
              entry: e,
              active: current == e.route ||
                  current.startsWith('${e.route}/'),
            ),
        ],
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(entry.icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              entry.label,
              style: AppTheme.sans(
                size: 10.5,
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
