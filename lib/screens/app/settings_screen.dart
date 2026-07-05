import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../core/errors.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/edge_buttons.dart';
import '../../widgets/edge_card.dart';
import '../../widgets/edge_input.dart';
import '../../widgets/page_header.dart';
import '../../widgets/toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _editingAccount = false;
  final _accountSize = TextEditingController();
  String _accountType = '';
  bool _accountBusy = false;
  bool _confirming = false;
  final _confirmEmail = TextEditingController();
  bool _deleting = false;
  bool _discoverBusy = false;

  @override
  void dispose() {
    _accountSize.dispose();
    _confirmEmail.dispose();
    super.dispose();
  }

  Future<void> _saveAccount(String email) async {
    final size = int.tryParse(_accountSize.text.trim()) ?? 0;
    if (_accountType.isEmpty || size <= 0) return;
    setState(() => _accountBusy = true);
    try {
      final api = context.read<ApiClient>();
      await api.dio.patch('/auth/me/', data: {
        'account_type': _accountType,
        'account_size': size,
      });
      await context.read<AuthState>().refreshProfile();
      ToastMessenger.instance.success('Trading account updated.');
      setState(() => _editingAccount = false);
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _accountBusy = false);
    }
  }

  Future<void> _toggleDiscoverable(bool current) async {
    setState(() => _discoverBusy = true);
    try {
      final api = context.read<ApiClient>();
      await api.dio
          .patch('/auth/me/', data: {'discoverable': !current});
      await context.read<AuthState>().refreshProfile();
      ToastMessenger.instance.success(!current
          ? 'You now appear in Discover.'
          : 'You are hidden from Discover.');
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _discoverBusy = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await context.read<AuthState>().deleteAccount();
      ToastMessenger.instance.success('Your account has been deleted.');
      if (mounted) context.go('/login');
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _copy(String text, String label) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    ToastMessenger.instance.success('$label copied.');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          eyebrow: 'Account',
          title: Text('Settings'),
          subtitle: 'Manage your profile and account.',
        ),
        const SizedBox(height: 18),
        EdgeCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _row('NAME', user.fullName ?? '—'),
              const Divider(color: EdgeColors.white06, height: 1),
              _row('EMAIL', user.email),
              const Divider(color: EdgeColors.white06, height: 1),
              _accountBlock(user.accountType, user.accountSize),
            ],
          ),
        ),
        const SizedBox(height: 14),
        EdgeCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: EdgeColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EdgeColors.accent.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  user.discoverable
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: user.discoverable
                      ? EdgeColors.accent
                      : EdgeColors.muted,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Discoverability',
                        style: AppTheme.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      'When discoverable, others can find you in Discover and sync their subscription to yours.',
                      style: AppTheme.sans(
                        size: 11.5,
                        color: EdgeColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: user.discoverable,
                onChanged: _discoverBusy
                    ? null
                    : (_) => _toggleDiscoverable(user.discoverable),
                activeColor: Colors.white,
                activeTrackColor: EdgeColors.accent,
                inactiveTrackColor: EdgeColors.surface,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        EdgeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: EdgeColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            EdgeColors.accent.withOpacity(0.2),
                      ),
                    ),
                    child: const Icon(Icons.card_giftcard_outlined,
                        color: EdgeColors.accent, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invite friends',
                            style: AppTheme.sans(
                              size: 13,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          "Share your invitation code. When pricing launches, you'll earn credit for every signup that used your code.",
                          style: AppTheme.sans(
                            size: 11.5,
                            color: EdgeColors.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('YOUR CODE', style: AppTheme.label()),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: EdgeColors.border),
                        borderRadius: BorderRadius.circular(12),
                        color: EdgeColors.surface.withOpacity(0.5),
                      ),
                      child: Text(
                        user.referralCode ?? '—',
                        style: AppTheme.mono(
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  EdgeButton(
                    label: 'Copy',
                    icon: Icons.copy_outlined,
                    kind: EdgeButtonKind.ghost,
                    onPressed: () =>
                        _copy(user.referralCode ?? '', 'Code'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.people_outline,
                      size: 14, color: EdgeColors.muted),
                  const SizedBox(width: 8),
                  Text(
                    '${user.referralsCount} ${user.referralsCount == 1 ? 'person has' : 'people have'} signed up with your code.',
                    style: AppTheme.sans(
                      size: 11.5,
                      color: EdgeColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        EdgeCard(
          borderColor: EdgeColors.danger.withOpacity(0.3),
          tint: EdgeColors.danger.withOpacity(0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 18, color: EdgeColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete account',
                            style: AppTheme.sans(
                              size: 13,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          'This permanently removes your account, subscriptions, analysis history, and any linked Telegram. This cannot be undone.',
                          style: AppTheme.sans(
                            size: 11.5,
                            color: EdgeColors.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!_confirming)
                Align(
                  alignment: Alignment.centerLeft,
                  child: EdgeButton(
                    label: 'Delete my account',
                    icon: Icons.delete_outline,
                    kind: EdgeButtonKind.danger,
                    onPressed: () => setState(() => _confirming = true),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Type your email (${user.email}) to confirm.',
                        style: AppTheme.label()),
                    const SizedBox(height: 8),
                    EdgeInput(
                      controller: _confirmEmail,
                      hint: user.email,
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        EdgeButton(
                          label: 'Cancel',
                          kind: EdgeButtonKind.ghost,
                          onPressed: () {
                            setState(() {
                              _confirming = false;
                              _confirmEmail.clear();
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        EdgeButton(
                          label: 'Delete account',
                          kind: EdgeButtonKind.danger,
                          busy: _deleting,
                          onPressed: _confirmEmail.text
                                      .trim()
                                      .toLowerCase() ==
                                  user.email.toLowerCase()
                              ? _delete
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Text(label,
                style: AppTheme.sans(
                  size: 10.5,
                  weight: FontWeight.w600,
                  color: EdgeColors.muted,
                  letterSpacing: 1.6,
                )),
            const Spacer(),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sans(
                    size: 12.5, color: Colors.white),
              ),
            ),
          ],
        ),
      );

  Widget _accountBlock(String? currentType, int? currentSize) {
    if (!_editingAccount) {
      final type = currentType == null
          ? '—'
          : currentType == 'propfirm'
              ? 'Prop firm'
              : 'Live';
      final size =
          currentSize != null ? ' · \$$currentSize' : '';
      return Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TRADING ACCOUNT',
                      style: AppTheme.sans(
                        size: 10.5,
                        weight: FontWeight.w600,
                        color: EdgeColors.muted,
                        letterSpacing: 1.6,
                      )),
                  const SizedBox(height: 4),
                  Text('$type$size',
                      style: AppTheme.sans(
                          size: 12.5, color: Colors.white)),
                ],
              ),
            ),
            EdgeButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              kind: EdgeButtonKind.ghost,
              onPressed: () {
                setState(() {
                  _editingAccount = true;
                  _accountType = currentType ?? '';
                  _accountSize.text =
                      currentSize?.toString() ?? '';
                });
              },
            ),
          ],
        ),
      );
    }
    final user = context.read<AuthState>().user!;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('TRADING ACCOUNT',
              style: AppTheme.sans(
                size: 10.5,
                weight: FontWeight.w600,
                color: EdgeColors.muted,
                letterSpacing: 1.6,
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _acctBtn('Prop firm', Icons.work_outline,
                    _accountType == 'propfirm', () {
                  setState(() => _accountType = 'propfirm');
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _acctBtn('Live',
                    Icons.account_balance_wallet_outlined,
                    _accountType == 'live', () {
                  setState(() => _accountType = 'live');
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const EdgeLabel('Account size (USD)'),
          EdgeInput(
            controller: _accountSize,
            hint: '10000',
            keyboardType: TextInputType.number,
            leadingIcon: Icons.attach_money,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              EdgeButton(
                label: 'Cancel',
                kind: EdgeButtonKind.ghost,
                onPressed: () => setState(() {
                  _editingAccount = false;
                  _accountSize.clear();
                  _accountType = '';
                }),
              ),
              const SizedBox(width: 10),
              EdgeButton(
                label: 'Save',
                icon: Icons.check,
                busy: _accountBusy,
                onPressed: () => _saveAccount(user.email),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _acctBtn(String label, IconData icon, bool active,
      VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? EdgeColors.accent : EdgeColors.border,
          ),
          color: active
              ? EdgeColors.accent.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: active ? EdgeColors.accent : EdgeColors.slate300),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.sans(
                size: 12.5,
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
