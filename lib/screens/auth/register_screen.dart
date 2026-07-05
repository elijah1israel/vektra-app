import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.referralCode});
  final String? referralCode;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _steps = ['Details', 'Security', 'Confirm'];
  static const _copy = [
    ('Create your account', "Let's start with your details."),
    ('Secure your account', 'Choose a strong password.'),
    ('Almost there', 'Review and confirm your details.'),
  ];

  int _step = 0;
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _accountSize = TextEditingController();
  late final TextEditingController _referral =
      TextEditingController(text: widget.referralCode?.toUpperCase() ?? '');
  String _accountType = '';
  bool _showPw = false;
  bool _agree = false;
  bool _busy = false;
  bool _sent = false;
  bool _resent = false;

  @override
  void dispose() {
    for (final c in [
      _first,
      _last,
      _email,
      _password,
      _confirm,
      _accountSize,
      _referral,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _emailValid => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
      .hasMatch(_email.text.trim());
  int get _sizeNum => int.tryParse(_accountSize.text.trim()) ?? 0;
  bool get _sizeValid => _sizeNum > 0;
  List<(String, bool)> get _reqs => [
        ('At least 8 characters', _password.text.length >= 8),
        (
          'Contains a letter',
          RegExp(r'[a-zA-Z]').hasMatch(_password.text)
        ),
        ('Contains a number', RegExp(r'\d').hasMatch(_password.text)),
      ];
  int get _strength => _reqs.where((r) => r.$2).length;
  bool get _passwordsMatch =>
      _password.text.isNotEmpty && _password.text == _confirm.text;
  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _first.text.trim().isNotEmpty &&
            _emailValid &&
            _accountType.isNotEmpty &&
            _sizeValid;
      case 1:
        return _reqs[0].$2 && _passwordsMatch;
      case 2:
        return _agree;
    }
    return false;
  }

  Future<void> _submit() async {
    if (!_canAdvance || _busy) return;
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }
    setState(() => _busy = true);
    try {
      final payload = <String, dynamic>{
        'full_name':
            '${_first.text.trim()} ${_last.text.trim()}'.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'account_type': _accountType,
        'account_size': _sizeNum,
      };
      final code = _referral.text.trim().toUpperCase();
      if (code.isNotEmpty) payload['referral_code'] = code;
      await context.read<AuthState>().register(payload);
      setState(() => _sent = true);
    } catch (err) {
      ToastMessenger.instance.error(describeError(err));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await context
          .read<AuthState>()
          .resendVerification(_email.text.trim());
      setState(() => _resent = true);
      ToastMessenger.instance
          .success('Verification email sent — check your inbox.');
    } catch (_) {
      setState(() => _resent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return AuthShell(
        title: 'Check your email',
        subtitle: 'One last step to activate your account.',
        footer: Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text('Wrong address? ',
                style: AppTheme.sans(
                    size: 13, color: EdgeColors.muted)),
            InlineLink(
              label: 'Start over',
              onTap: () => setState(() {
                _sent = false;
                _step = 0;
              }),
            ),
          ],
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
            const SizedBox(height: 20),
            Text(
              'We sent a verification link to ${_email.text.trim()}. Tap it to activate your account.',
              textAlign: TextAlign.center,
              style: AppTheme.sans(
                size: 13,
                color: EdgeColors.slate300,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text("Didn't get it? ",
                    style: AppTheme.sans(
                        size: 12, color: EdgeColors.muted)),
                InlineLink(label: 'Resend', onTap: _resend),
              ],
            ),
            if (_resent) ...[
              const SizedBox(height: 6),
              Text('Verification email re-sent.',
                  style: AppTheme.sans(
                      size: 12, color: EdgeColors.accent)),
            ],
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
      title: _copy[_step].$1,
      subtitle: _copy[_step].$2,
      footer: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text('Already have an account? ',
              style: AppTheme.sans(
                  size: 13, color: EdgeColors.muted)),
          InlineLink(
            label: 'Sign in',
            onTap: () => context.go('/login'),
          ),
        ],
      ),
      child: Column(
        children: [
          _StepDots(step: _step, total: _steps.length),
          const SizedBox(height: 18),
          if (_step == 0) _detailsStep(),
          if (_step == 1) _securityStep(),
          if (_step == 2) _reviewStep(),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_step > 0) ...[
                EdgeButton(
                  label: 'Back',
                  icon: Icons.arrow_back,
                  kind: EdgeButtonKind.ghost,
                  onPressed: () => setState(() => _step -= 1),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: EdgeButton(
                  label: _step < 2 ? 'Continue' : 'Create account',
                  trailing:
                      _step < 2 ? Icons.arrow_forward : null,
                  busy: _busy,
                  fullWidth: true,
                  onPressed: _canAdvance ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EdgeLabel('First name'),
                  EdgeInput(
                    controller: _first,
                    hint: 'Jane',
                    autofocus: true,
                    leadingIcon: Icons.person_outline,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EdgeLabel('Last name'),
                  EdgeInput(
                    controller: _last,
                    hint: 'Trader',
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const EdgeLabel('Email'),
        EdgeInput(
          controller: _email,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          leadingIcon: Icons.mail_outline,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        const EdgeLabel('Account type'),
        Row(
          children: [
            Expanded(
              child: _AccountTypeChip(
                label: 'Prop firm',
                icon: Icons.work_outline,
                active: _accountType == 'propfirm',
                onTap: () =>
                    setState(() => _accountType = 'propfirm'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AccountTypeChip(
                label: 'Live',
                icon: Icons.account_balance_wallet_outlined,
                active: _accountType == 'live',
                onTap: () => setState(() => _accountType = 'live'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const EdgeLabel('Account size (USD)'),
        EdgeInput(
          controller: _accountSize,
          hint: '10000',
          keyboardType: TextInputType.number,
          leadingIcon: Icons.attach_money,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
        ),
        if (_accountSize.text.isNotEmpty && !_sizeValid) ...[
          const SizedBox(height: 6),
          Text(
            'Enter a positive whole-number amount in USD.',
            style: AppTheme.sans(size: 11.5, color: EdgeColors.danger),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Text('Invitation code ',
                style: AppTheme.label()),
            Text('(optional)',
                style: AppTheme.sans(
                    size: 11, color: EdgeColors.muted)),
          ],
        ),
        const SizedBox(height: 6),
        EdgeInput(
          controller: _referral,
          hint: 'ABCD1234',
          leadingIcon: Icons.card_giftcard_outlined,
          maxLength: 16,
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) {
            final upper = v.toUpperCase();
            if (upper != v) {
              _referral.value = TextEditingValue(
                text: upper,
                selection: TextSelection.collapsed(offset: upper.length),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _securityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EdgeLabel('Password'),
        EdgeInput(
          controller: _password,
          hint: 'Create a password',
          obscureText: !_showPw,
          autofocus: true,
          leadingIcon: Icons.lock_outline,
          onChanged: (_) => setState(() {}),
          trailing: IconButton(
            splashRadius: 20,
            onPressed: () => setState(() => _showPw = !_showPw),
            icon: Icon(
              _showPw ? Icons.visibility_off : Icons.visibility,
              size: 16,
              color: EdgeColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(3, (i) {
            final ok = _strength > i;
            Color color = EdgeColors.border;
            if (ok) {
              color = _strength == 1
                  ? EdgeColors.danger
                  : _strength == 2
                      ? EdgeColors.warning
                      : EdgeColors.accent;
            }
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        ..._reqs.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  size: 12,
                  color: r.$2
                      ? EdgeColors.accent
                      : EdgeColors.muted.withOpacity(0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  r.$1,
                  style: AppTheme.sans(
                    size: 11.5,
                    color:
                        r.$2 ? EdgeColors.accent : EdgeColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const EdgeLabel('Confirm password'),
        EdgeInput(
          controller: _confirm,
          hint: 'Re-enter your password',
          obscureText: !_showPw,
          leadingIcon: Icons.lock_outline,
          onChanged: (_) => setState(() {}),
        ),
        if (_confirm.text.isNotEmpty && !_passwordsMatch) ...[
          const SizedBox(height: 6),
          Text(
            "Passwords don't match.",
            style: AppTheme.sans(size: 11.5, color: EdgeColors.danger),
          ),
        ],
      ],
    );
  }

  Widget _reviewStep() {
    final fullName =
        '${_first.text.trim()} ${_last.text.trim()}'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: EdgeColors.border),
            borderRadius: BorderRadius.circular(14),
            color: EdgeColors.surface.withOpacity(0.5),
          ),
          child: Column(
            children: [
              _reviewRow(Icons.person_outline, fullName.isEmpty ? '—' : fullName),
              _divider(),
              _reviewRow(Icons.mail_outline, _email.text.trim()),
              _divider(),
              _reviewRow(
                Icons.work_outline,
                '${_accountType == 'propfirm' ? 'Prop firm' : 'Live'} account · \$$_sizeNum',
              ),
              _divider(),
              _reviewRow(Icons.lock_outline, '••••••••'),
              if (_referral.text.trim().isNotEmpty) ...[
                _divider(),
                _reviewRow(
                  Icons.card_giftcard_outlined,
                  _referral.text.trim().toUpperCase(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agree,
              onChanged: (v) => setState(() => _agree = v ?? false),
              activeColor: EdgeColors.accent,
              checkColor: EdgeColors.bg,
              side: const BorderSide(color: EdgeColors.border),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text.rich(
                  TextSpan(
                    style: AppTheme.sans(
                      size: 11.5,
                      color: EdgeColors.muted,
                      height: 1.55,
                    ),
                    children: const [
                      TextSpan(text: 'I agree to VektraPro\'s '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(color: EdgeColors.accent),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(color: EdgeColors.accent),
                      ),
                      TextSpan(
                        text:
                            ', and understand this is not financial advice.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewRow(IconData icon, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: EdgeColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sans(size: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      );

  Widget _divider() =>
      const Divider(color: EdgeColors.white06, height: 1);
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step, required this.total});
  final int step;
  final int total;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < total; i++) ...[
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < step ? EdgeColors.accent : Colors.transparent,
              border: Border.all(
                color: i <= step ? EdgeColors.accent : EdgeColors.border,
              ),
            ),
            child: i < step
                ? const Icon(Icons.check,
                    size: 12, color: EdgeColors.bg)
                : Text(
                    '${i + 1}',
                    style: AppTheme.sans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: i == step
                          ? EdgeColors.accent
                          : EdgeColors.muted,
                    ),
                  ),
          ),
          if (i < total - 1)
            Container(
              width: 22,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color:
                  i < step ? EdgeColors.accent : EdgeColors.border,
            ),
        ],
      ],
    );
  }
}

class _AccountTypeChip extends StatelessWidget {
  const _AccountTypeChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: active
              ? EdgeColors.accent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? EdgeColors.accent : EdgeColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15,
                color: active ? EdgeColors.accent : EdgeColors.slate300),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.sans(
                size: 13,
                weight: FontWeight.w600,
                color:
                    active ? EdgeColors.accent : EdgeColors.slate300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
