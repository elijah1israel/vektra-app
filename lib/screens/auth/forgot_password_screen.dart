import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/edge_buttons.dart';
import '../../widgets/edge_input.dart';
import '../../widgets/toast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await context
          .read<AuthState>()
          .requestPasswordReset(_email.text.trim());
      setState(() => _sent = true);
    } catch (err) {
      ToastMessenger.instance.error(describeError(err));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return AuthShell(
        title: 'Check your email',
        subtitle: 'Your reset link is on the way.',
        footer: InlineLink(
          label: 'Back to sign in',
          onTap: () => context.go('/login'),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EdgeColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: EdgeColors.accent.withOpacity(0.2),
                ),
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  color: EdgeColors.accent, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              "If an account exists for ${_email.text.trim()}, we've sent a link to reset your password.",
              textAlign: TextAlign.center,
              style: AppTheme.sans(
                size: 13,
                color: EdgeColors.slate300,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            EdgeButton(
              label: 'Back to sign in',
              kind: EdgeButtonKind.ghost,
              fullWidth: true,
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      );
    }
    return AuthShell(
      title: 'Forgot password?',
      subtitle: "Enter your email and we'll send a reset link.",
      footer: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text('Remembered it? ',
              style: AppTheme.sans(
                  size: 13, color: EdgeColors.muted)),
          InlineLink(
            label: 'Sign in',
            onTap: () => context.go('/login'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EdgeLabel('Email'),
          EdgeInput(
            controller: _email,
            hint: 'you@example.com',
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          EdgeButton(
            label: 'Send reset link',
            busy: _busy,
            fullWidth: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
