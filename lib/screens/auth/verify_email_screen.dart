import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/edge_buttons.dart';
import '../../widgets/spinner.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.token});
  final String? token;
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String _state = 'verifying';
  String _message = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _state = 'error';
        _message = 'This verification link is missing its token.';
      });
      return;
    }
    try {
      await context.read<AuthState>().verifyEmail(token);
      setState(() => _state = 'success');
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) context.go('/dashboard');
    } catch (err) {
      setState(() {
        _state = 'error';
        _message = describeError(
            err, 'This verification link is invalid or has expired.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Email verification',
      subtitle: 'Activating your VektraPro account.',
      footer: InlineLink(
        label: 'Back to sign in',
        onTap: () => context.go('/login'),
      ),
      child: Column(
        children: [
          if (_state == 'verifying') ...[
            const Spinner(size: 36, color: EdgeColors.accent),
            const SizedBox(height: 14),
            Text('Verifying your email…',
                style: AppTheme.sans(
                    size: 13, color: EdgeColors.muted)),
          ] else if (_state == 'success') ...[
            const Icon(Icons.check_circle_outline,
                color: EdgeColors.accent, size: 44),
            const SizedBox(height: 14),
            Text('Email verified — signing you in…',
                style: AppTheme.sans(
                    size: 13, color: EdgeColors.slate200)),
          ] else ...[
            const Icon(Icons.cancel_outlined,
                color: EdgeColors.danger, size: 44),
            const SizedBox(height: 14),
            Text(
              _message,
              textAlign: TextAlign.center,
              style:
                  AppTheme.sans(size: 13, color: EdgeColors.slate200),
            ),
            const SizedBox(height: 20),
            EdgeButton(
              label: 'Back to sign in',
              kind: EdgeButtonKind.ghost,
              fullWidth: true,
              onPressed: () => context.go('/login'),
            ),
          ],
        ],
      ),
    );
  }
}
