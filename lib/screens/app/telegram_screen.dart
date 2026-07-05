import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_client.dart';
import '../../core/errors.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/edge_buttons.dart';
import '../../widgets/edge_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/toast.dart';

class TelegramScreen extends StatefulWidget {
  const TelegramScreen({super.key});
  @override
  State<TelegramScreen> createState() => _TelegramScreenState();
}

class _TelegramScreenState extends State<TelegramScreen> {
  Map<String, dynamic>? _status;
  Map<String, dynamic>? _code;
  bool _busy = false;
  bool _copied = false;
  int? _remaining;
  Timer? _pollTimer;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/telegram/status/');
      setState(() => _status = (res.data as Map).cast<String, dynamic>());
    } catch (_) {}
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.post('/telegram/pair/');
      setState(() => _code = (res.data as Map).cast<String, dynamic>());
      _startPolling();
      _startTicking();
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unpair() async {
    try {
      final api = context.read<ApiClient>();
      await api.dio.post('/telegram/unpair/');
      setState(() {
        _code = null;
        _remaining = null;
      });
      await _loadStatus();
      await context.read<AuthState>().refreshProfile();
      ToastMessenger.instance.info('Telegram unlinked.');
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final api = context.read<ApiClient>();
        final res = await api.dio.get('/telegram/status/');
        final data = (res.data as Map).cast<String, dynamic>();
        setState(() => _status = data);
        if (data['linked'] == true) {
          _pollTimer?.cancel();
          setState(() => _code = null);
          await context.read<AuthState>().refreshProfile();
          ToastMessenger.instance
              .success('Telegram linked! Trade plans will be delivered to you.');
        }
      } catch (_) {}
    });
  }

  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final expiresAt = _code?['expires_at'] as String?;
      if (expiresAt == null) return;
      try {
        final diff = DateTime.parse(expiresAt)
                .difference(DateTime.now())
                .inSeconds;
        setState(() => _remaining = diff > 0 ? diff : 0);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final linked = _status?['linked'] == true;
    final expired = _remaining == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          eyebrow: 'Delivery',
          title: Text('Telegram'),
          subtitle:
              'Link your Telegram so the bot can deliver trade plans to you individually.',
        ),
        const SizedBox(height: 18),
        if (linked)
          _LinkedCard(
            account: (_status?['account'] as Map?)?.cast<String, dynamic>(),
            onUnpair: _unpair,
          )
        else
          EdgeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Step(
                  n: '1',
                  title: 'Generate a pairing code',
                  child: _code == null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: EdgeButton(
                            label: 'Generate code',
                            icon: Icons.send,
                            busy: _busy,
                            onPressed: _generate,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: EdgeColors.surface
                                            .withOpacity(0.8),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: EdgeColors.accent
                                              .withOpacity(0.25),
                                        ),
                                      ),
                                      child: Text(
                                        _code!['code'] as String,
                                        textAlign: TextAlign.center,
                                        style: AppTheme.mono(
                                          size: 24,
                                          weight: FontWeight.w700,
                                          color: EdgeColors.accentHi,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  EdgeButton(
                                    label: _copied ? 'Copied' : 'Copy',
                                    icon: _copied
                                        ? Icons.check
                                        : Icons.copy_outlined,
                                    kind: EdgeButtonKind.ghost,
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(
                                          text:
                                              '/pair ${_code!['code']}',
                                        ),
                                      );
                                      setState(() => _copied = true);
                                      await Future.delayed(
                                          const Duration(
                                              milliseconds: 1500));
                                      if (mounted) {
                                        setState(() => _copied = false);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined,
                                      size: 13,
                                      color: expired
                                          ? EdgeColors.danger
                                          : EdgeColors.muted),
                                  const SizedBox(width: 6),
                                  Text(
                                    expired
                                        ? 'Code expired.'
                                        : 'Expires in ${_fmt(_remaining ?? 0)}',
                                    style: AppTheme.sans(
                                      size: 12,
                                      color: expired
                                          ? EdgeColors.danger
                                          : EdgeColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                _Step(
                  n: '2',
                  title: 'Send it to the bot',
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open the bot and send /pair ${_code?['code'] ?? 'CODE'}.',
                          style: AppTheme.sans(
                              size: 12.5, color: EdgeColors.muted),
                        ),
                        if (_code?['bot_username'] != null) ...[
                          const SizedBox(height: 10),
                          EdgeButton(
                            label: 'Open bot',
                            icon: Icons.send,
                            kind: EdgeButtonKind.ghost,
                            onPressed: () async {
                              final url = Uri.parse(
                                  'https://t.me/${_code!['bot_username']}');
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _Step(
                  n: '3',
                  title: 'Done',
                  last: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _code == null
                          ? 'This page updates automatically once linked.'
                          : expired
                              ? 'Generate a fresh code to continue.'
                              : 'Waiting for you to confirm in Telegram…',
                      style: AppTheme.sans(
                          size: 12.5, color: EdgeColors.muted),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _fmt(int secs) =>
      '${(secs ~/ 60)}:${(secs % 60).toString().padLeft(2, '0')}';
}

/// Profile-style block for the linked state. Shows the Telegram username
/// (or a friendly fallback), the chat / user id, and when the account
/// was paired — followed by an "Unlink" action.
class _LinkedCard extends StatelessWidget {
  const _LinkedCard({required this.account, required this.onUnpair});

  final Map<String, dynamic>? account;
  final Future<void> Function() onUnpair;

  @override
  Widget build(BuildContext context) {
    final username = (account?['telegram_username'] as String?) ?? '';
    final chatId = account?['telegram_chat_id'];
    final pairedAt = account?['paired_at'] as String?;
    final displayHandle = username.isNotEmpty ? '@$username' : 'Private account';
    final chatText = chatId != null ? chatId.toString() : '—';
    String pairedText = '—';
    if (pairedAt != null) {
      try {
        pairedText =
            DateFormat("d MMM yyyy 'at' HH:mm").format(DateTime.parse(pairedAt).toLocal());
      } catch (_) {
        pairedText = pairedAt;
      }
    }

    return EdgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2AABEE), Color(0xFF229ED9)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF229ED9).withOpacity(0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Telegram linked',
                            style: AppTheme.sans(
                              size: 14.5,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            )),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: EdgeColors.accent.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: EdgeColors.accent.withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: EdgeColors.accent, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                'ACTIVE',
                                style: AppTheme.sans(
                                  size: 9.5,
                                  color: EdgeColors.accent,
                                  weight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Trade plans are delivered to this account.',
                      style: AppTheme.sans(
                        size: 11.5,
                        color: EdgeColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _KvRow(
            icon: Icons.alternate_email,
            label: 'Username',
            value: displayHandle,
            hint: username.isEmpty ? 'Not set on Telegram' : null,
          ),
          const Divider(color: EdgeColors.white06, height: 20),
          _KvRow(
            icon: Icons.tag,
            label: 'Telegram ID',
            value: chatText,
            copyable: chatId != null,
          ),
          const Divider(color: EdgeColors.white06, height: 20),
          _KvRow(
            icon: Icons.calendar_today_outlined,
            label: 'Linked on',
            value: pairedText,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              EdgeButton(
                label: 'Unlink',
                icon: Icons.link_off,
                kind: EdgeButtonKind.danger,
                onPressed: () => onUnpair(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: EdgeColors.muted),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTheme.sans(
            size: 11.5,
            color: EdgeColors.muted,
            weight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.mono(
              size: 13,
              color: Colors.white,
              weight: FontWeight.w500,
            ),
          ),
        ),
        if (copyable) ...[
          const SizedBox(width: 8),
          _CopyButton(text: value),
        ] else if (hint != null) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: hint!,
            child: const Icon(Icons.info_outline,
                size: 13, color: EdgeColors.muted),
          ),
        ],
      ],
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});
  final String text;
  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.text));
        setState(() => _copied = true);
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) setState(() => _copied = false);
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          _copied ? Icons.check : Icons.copy_outlined,
          size: 14,
          color: _copied ? EdgeColors.accent : EdgeColors.muted,
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.title,
    required this.child,
    this.last = false,
  });
  final String n;
  final String title;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EdgeColors.accent.withOpacity(0.1),
                border: Border.all(
                  color: EdgeColors.accent.withOpacity(0.4),
                ),
              ),
              child: Text(
                n,
                style: AppTheme.sans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: EdgeColors.accent,
                ),
              ),
            ),
            if (!last)
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      EdgeColors.accent.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTheme.sans(
                    size: 13,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  )),
              child,
            ],
          ),
        ),
      ],
    );
  }
}
