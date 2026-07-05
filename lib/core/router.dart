import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/app/dashboard_screen.dart';
import '../screens/app/discover_screen.dart';
import '../screens/app/instruments_screen.dart';
import '../screens/app/plans_screen.dart';
import '../screens/app/pricing_screen.dart';
import '../screens/app/settings_screen.dart';
import '../screens/app/subscribe_config_screen.dart';
import '../screens/app/telegram_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../state/auth_state.dart';
import '../widgets/app_shell.dart';
import '../widgets/spinner.dart';

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(AuthState auth) {
    auth.addListener(notifyListeners);
  }
}

GoRouter buildRouter(AuthState auth) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _AuthRefresh(auth),
    redirect: (ctx, state) {
      final path = state.uri.path;
      if (auth.loading) return null;
      final signedIn = auth.isSignedIn;
      final onAuthRoute = const [
        '/login',
        '/register',
        '/forgot-password',
      ].contains(path);
      final publicRoute = const [
        '/verify-email',
        '/reset-password',
      ].contains(path);
      if (!signedIn && !onAuthRoute && !publicRoute) return '/login';
      if (signedIn && onAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, state) => RegisterScreen(
          referralCode: state.uri.queryParameters['ref'],
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => VerifyEmailScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          uid: state.uri.queryParameters['uid'],
          token: state.uri.queryParameters['token'],
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/instruments',
            builder: (_, __) => const InstrumentsScreen(),
          ),
          GoRoute(
            path: '/instruments/:id/configure',
            builder: (_, state) => SubscribeConfigScreen(
              instrumentId:
                  int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/discover',
            builder: (_, __) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/pricing',
            builder: (_, __) => const PricingScreen(),
          ),
          GoRoute(
            path: '/telegram',
            builder: (_, __) => const TelegramScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/plans',
            builder: (_, __) => const PlansScreen(),
          ),
        ],
      ),
    ],
  );
}

class BootstrapGate extends StatelessWidget {
  const BootstrapGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Selector<AuthState, bool>(
      selector: (_, a) => a.loading,
      builder: (_, loading, __) {
        if (loading) {
          return const Scaffold(
            body: Center(child: PageSpinner()),
          );
        }
        return child;
      },
    );
  }
}
