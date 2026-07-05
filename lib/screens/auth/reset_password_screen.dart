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

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.uid, this.token});
  final String? uid;
  final String? token;
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _done = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text != _confirm.text) {
      ToastMessenger.instance.error("Passwords don't match.");
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AuthState>().confirmPasswordReset(
            widget.uid!,
            widget.token!,
            _password.text,
          );
      setState(() => _done = true);
      ToastMessenger.instance
          .success('Password updated — you can now sign in.');
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) context.go('/login');
    } catch (err) {
      ToastMessenger.instance.error(describeError(err));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uid == null || widget.token == null) {
      return AuthShell(
        title: 'Invalid link',
        subtitle: 'This password reset link is malformed.',
        footer: InlineLink(
          label: 'Back to sign in',
          onTap: () => context.go('/login'),
        ),
        child: EdgeButton(
          label: 'Request a new link',
          fullWidth: true,
          onPressed: () => context.go('/forgot-password'),
        ),
      );
    }
    if (_done) {
      return AuthShell(
        title: 'Password updated',
        subtitle: "You're all set.",
        footer: InlineLink(
          label: 'Back to sign in',
          onTap: () => context.go('/login'),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline,
                color: EdgeColors.accent, size: 44),
            const SizedBox(height: 12),
            Text(
              'Your password has been changed — redirecting to sign in…',
              textAlign: TextAlign.center,
              style: AppTheme.sans(
                size: 13,
                color: EdgeColors.slate200,
              ),
            ),
          ],
        ),
      );
    }
    return AuthShell(
      title: 'Set a new password',
      subtitle: 'Choose a strong password for your account.',
      footer: InlineLink(
        label: 'Back to sign in',
        onTap: () => context.go('/login'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EdgeLabel('New password'),
          EdgeInput(
            controller: _password,
            hint: 'At least 8 characters',
            obscureText: true,
            autofocus: true,
          ),
          const SizedBox(height: 14),
          const EdgeLabel('Confirm password'),
          EdgeInput(
            controller: _confirm,
            hint: 'Re-enter your password',
            obscureText: true,
          ),
          const SizedBox(height: 18),
          EdgeButton(
            label: 'Update password',
            fullWidth: true,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
