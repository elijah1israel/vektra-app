import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          EdgeCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: EdgeColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: EdgeColors.accent.withOpacity(0.25),
                    ),
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      color: EdgeColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Telegram linked',
                          style: AppTheme.sans(
                            size: 14,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          )),
                      const SizedBox(height: 3),
                      Text(
                        _status?['account'] is Map &&
                                (_status!['account']
                                        as Map)['telegram_username'] !=
                                    null
                            ? '@${(_status!['account'] as Map)['telegram_username']}'
                            : 'chat ${(_status?['account'] as Map?)?['telegram_chat_id'] ?? '—'}',
                        style: AppTheme.sans(
                            size: 12, color: EdgeColors.muted),
                      ),
                    ],
                  ),
                ),
                EdgeButton(
                  label: 'Unlink',
                  icon: Icons.link_off,
                  kind: EdgeButtonKind.danger,
                  onPressed: _unpair,
                ),
              ],
            ),
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
