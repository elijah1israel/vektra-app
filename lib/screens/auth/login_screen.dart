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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _unverified = false;
  bool _resent = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _unverified = false;
      _resent = false;
    });
    try {
      await context.read<AuthState>().login(
            _email.text.trim(),
            _password.text,
          );
      if (mounted) context.go('/dashboard');
    } catch (err) {
      if (errorCode(err) == 'email_not_verified') {
        setState(() => _unverified = true);
      } else {
        ToastMessenger.instance.error(describeError(err));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await context.read<AuthState>().resendVerification(_email.text.trim());
      setState(() => _resent = true);
      ToastMessenger.instance
          .success('Verification email sent — check your inbox.');
    } catch (_) {
      setState(() => _resent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Welcome back',
      subtitle: 'Sign in to manage your signals.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text('New here? ',
              style:
                  AppTheme.sans(size: 13, color: EdgeColors.muted)),
          InlineLink(
            label: 'Create an account',
            onTap: () => context.push('/register'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_unverified) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EdgeColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EdgeColors.warning.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please verify your email before signing in.',
                    style: AppTheme.sans(
                      size: 12.5,
                      color: EdgeColors.slate200,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_resent)
                    Text(
                      'Verification email re-sent.',
                      style: AppTheme.sans(
                        size: 12,
                        color: EdgeColors.accent,
                      ),
                    )
                  else
                    InlineLink(
                      label: 'Resend link',
                      onTap: _resend,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          const EdgeLabel('Email'),
          EdgeInput(
            controller: _email,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const EdgeLabel('Password'),
              InlineLink(
                label: 'Forgot password?',
                onTap: () => context.push('/forgot-password'),
              ),
            ],
          ),
          EdgeInput(
            controller: _password,
            hint: '••••••••',
            obscureText: true,
          ),
          const SizedBox(height: 18),
          EdgeButton(
            label: 'Sign in',
            fullWidth: true,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
