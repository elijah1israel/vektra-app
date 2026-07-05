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
import '../../widgets/toast.dart';

const _timeframes = ['W1', 'D1', 'H4', 'H1', 'M15', 'M5'];
const _sessionTzs = <(String, String)>[
  ('UTC', 'UTC — Crypto (24/7)'),
  ('America/New_York', 'America/New_York — FX / Metals'),
];

/// Owner-only "Add instrument" form. Runs `POST /instruments/test_scrape/`
/// against the current field values before letting the owner commit the
/// row, so a bad symbol / prefix combination surfaces before it hits the
/// catalog.
class NewInstrumentScreen extends StatefulWidget {
  const NewInstrumentScreen({super.key});
  @override
  State<NewInstrumentScreen> createState() => _NewInstrumentScreenState();
}

class _NewInstrumentScreenState extends State<NewInstrumentScreen> {
  final _key = TextEditingController();
  final _label = TextEditingController();
  final _emoji = TextEditingController();
  final _symbol = TextEditingController();
  final _prefix = TextEditingController();
  final _bias = TextEditingController();
  final _compLabel = TextEditingController();
  final _compSymbol = TextEditingController();
  final _compPrefix = TextEditingController();
  String _sessionTz = 'UTC';
  final Set<String> _tfSel = {'D1', 'H4'};
  final Set<String> _compTfSel = {};
  bool _addCompanion = false;
  bool _testing = false;
  bool _creating = false;
  Map<String, dynamic>? _testResult;

  @override
  void dispose() {
    for (final c in [
      _key, _label, _emoji, _symbol, _prefix, _bias,
      _compLabel, _compSymbol, _compPrefix,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _autoDeriveFromLabel(String v) {
    // Nudge `key` and `prefix` from `label` if the user hasn't typed
    // them yet — same "btcusd" slug both fields commonly share.
    final slug =
        v.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    if (_key.text.isEmpty) _key.text = slug;
    if (_prefix.text.isEmpty) _prefix.text = slug;
  }

  Map<String, dynamic> _payload({required bool forCreate}) {
    final body = <String, dynamic>{
      'label': _label.text.trim(),
      'symbol': _symbol.text.trim(),
      'prefix': _prefix.text.trim(),
      'timeframes': _tfSel.toList(),
      'session_tz': _sessionTz,
    };
    if (_emoji.text.trim().isNotEmpty) body['emoji'] = _emoji.text.trim();
    if (_addCompanion &&
        _compSymbol.text.trim().isNotEmpty &&
        _compPrefix.text.trim().isNotEmpty) {
      body['companion_label'] = _compLabel.text.trim();
      body['companion_symbol'] = _compSymbol.text.trim();
      body['companion_prefix'] = _compPrefix.text.trim();
      body['companion_timeframes'] = _compTfSel.toList();
    }
    if (forCreate) {
      body['key'] = _key.text.trim();
      if (_bias.text.trim().isNotEmpty) body['bias'] = _bias.text.trim();
    }
    return body;
  }

  bool get _canTest =>
      _label.text.trim().isNotEmpty &&
      _symbol.text.trim().isNotEmpty &&
      _prefix.text.trim().isNotEmpty &&
      _tfSel.isNotEmpty;

  bool get _canCreate => _canTest && _key.text.trim().isNotEmpty;

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final api = context.read<ApiClient>();
      // Scraping can take 30–60s; the default receive timeout on Dio is
      // 30s, bump it just for this call.
      final res = await api.dio.post(
        '/instruments/test_scrape/',
        data: _payload(forCreate: false),
        options: Options(receiveTimeout: const Duration(seconds: 180)),
      );
      setState(() =>
          _testResult = (res.data as Map).cast<String, dynamic>());
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      final api = context.read<ApiClient>();
      await api.dio.post(
        '/instruments/',
        data: _payload(forCreate: true),
      );
      ToastMessenger.instance
          .success('${_label.text.trim()} added to the catalog.');
      if (mounted) context.go('/instruments');
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    if (user == null || !user.isBotOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/instruments');
      });
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.go('/instruments'),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              splashRadius: 20,
            ),
            const SizedBox(width: 4),
            Text('New instrument',
                style: AppTheme.display(
                  size: 22,
                  weight: FontWeight.w700,
                  letterSpacing: -0.4,
                )),
          ],
        ),
        const SizedBox(height: 14),
        _section(
          title: 'Identity',
          desc: 'How the pair is labelled and slugged internally.',
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EdgeLabel('Emoji'),
                      EdgeInput(
                        controller: _emoji,
                        hint: '🪙',
                        maxLength: 4,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EdgeLabel('Label'),
                      EdgeInput(
                        controller: _label,
                        hint: 'BTCUSD',
                        onChanged: (v) {
                          _autoDeriveFromLabel(v);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EdgeLabel('Key (slug)'),
                      EdgeInput(
                        controller: _key,
                        hint: 'btcusd',
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EdgeLabel('Screenshot prefix'),
                      EdgeInput(
                        controller: _prefix,
                        hint: 'btcusd',
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        _section(
          title: 'Chart source',
          desc:
              'TradingView symbol the scraper opens, and the session tz that anchors candle closes.',
          children: [
            const EdgeLabel('TradingView symbol'),
            EdgeInput(
              controller: _symbol,
              hint: 'COINBASE:BTCUSD',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const EdgeLabel('Session timezone'),
            _sessionDropdown(),
            const SizedBox(height: 12),
            const EdgeLabel('Timeframes to capture'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeframes
                  .map((tf) => _chip(
                        label: tf,
                        active: _tfSel.contains(tf),
                        onTap: () {
                          setState(() {
                            if (_tfSel.contains(tf)) {
                              _tfSel.remove(tf);
                            } else {
                              _tfSel.add(tf);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
        _section(
          title: 'Correlation companion',
          desc:
              'Optional lead-indicator chart (e.g. DXY for USD-denominated pairs). Analysed alongside the main pair as context only.',
          trailing: Switch(
            value: _addCompanion,
            onChanged: (v) => setState(() => _addCompanion = v),
            activeColor: Colors.white,
            activeTrackColor: EdgeColors.accent,
          ),
          children: !_addCompanion
              ? const []
              : [
                  const EdgeLabel('Companion label'),
                  EdgeInput(controller: _compLabel, hint: 'DXY'),
                  const SizedBox(height: 12),
                  const EdgeLabel('Companion symbol'),
                  EdgeInput(
                      controller: _compSymbol, hint: 'TVC:DXY'),
                  const SizedBox(height: 12),
                  const EdgeLabel('Companion prefix'),
                  EdgeInput(controller: _compPrefix, hint: 'dxy'),
                  const SizedBox(height: 12),
                  const EdgeLabel('Companion timeframes'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeframes
                        .map((tf) => _chip(
                              label: tf,
                              active: _compTfSel.contains(tf),
                              onTap: () {
                                setState(() {
                                  if (_compTfSel.contains(tf)) {
                                    _compTfSel.remove(tf);
                                  } else {
                                    _compTfSel.add(tf);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                ],
        ),
        _section(
          title: 'Prompt bias (optional)',
          desc:
              'One sentence describing how DXY leads this pair — folded into the auto-generated Claude prompt. Leave blank for a neutral default.',
          children: [
            EdgeInput(
              controller: _bias,
              hint:
                  'USD strength generally pushes BTCUSD down, USD weakness pulls it up.',
              inputFormatters: [
                LengthLimitingTextInputFormatter(240),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        _TestResultCard(result: _testResult),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: EdgeButton(
                label: _testing ? 'Scraping…' : 'Test scrape',
                icon: Icons.travel_explore,
                kind: EdgeButtonKind.ghost,
                fullWidth: true,
                busy: _testing,
                onPressed: _canTest ? _test : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: EdgeButton(
                label: 'Create',
                icon: Icons.check,
                fullWidth: true,
                busy: _creating,
                onPressed: _canCreate ? _create : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required String desc,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: EdgeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTheme.sans(
                            size: 14,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          )),
                      const SizedBox(height: 4),
                      Text(desc,
                          style: AppTheme.sans(
                            size: 11.5,
                            color: EdgeColors.muted,
                            height: 1.5,
                          )),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            if (children.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...children,
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? EdgeColors.accent.withOpacity(0.5)
                : EdgeColors.white08,
          ),
          color: active
              ? EdgeColors.accent.withOpacity(0.14)
              : EdgeColors.surface.withOpacity(0.5),
        ),
        child: Text(
          label,
          style: AppTheme.sans(
            size: 12.5,
            weight: FontWeight.w600,
            color:
                active ? EdgeColors.accentHi : EdgeColors.slate300,
          ),
        ),
      ),
    );
  }

  Widget _sessionDropdown() {
    return PopupMenuButton<String>(
      color: EdgeColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: EdgeColors.white10),
      ),
      itemBuilder: (ctx) => _sessionTzs
          .map((e) => PopupMenuItem<String>(
                value: e.$1,
                child: Text(e.$2,
                    style: AppTheme.sans(
                        size: 13, color: Colors.white)),
              ))
          .toList(),
      onSelected: (v) => setState(() => _sessionTz = v),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: EdgeColors.white10),
          borderRadius: BorderRadius.circular(12),
          color: EdgeColors.surface.withOpacity(0.6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _sessionTzs
                    .firstWhere((e) => e.$1 == _sessionTz,
                        orElse: () => _sessionTzs.first)
                    .$2,
                style:
                    AppTheme.sans(size: 13.5, color: Colors.white),
              ),
            ),
            const Icon(Icons.expand_more,
                color: EdgeColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TestResultCard extends StatelessWidget {
  const _TestResultCard({required this.result});
  final Map<String, dynamic>? result;

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();
    final ok = result!['success'] == true;
    final captured = (result!['captured'] as List?) ?? const [];
    final err = result!['error'] as String?;
    return EdgeCard(
      plain: true,
      borderColor: ok
          ? EdgeColors.accent.withOpacity(0.4)
          : EdgeColors.danger.withOpacity(0.4),
      tint: (ok ? EdgeColors.accent : EdgeColors.danger)
          .withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: ok ? EdgeColors.accent : EdgeColors.danger,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                ok
                    ? 'Captured ${captured.length} chart${captured.length == 1 ? '' : 's'}'
                    : 'Test scrape failed',
                style: AppTheme.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (captured.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: captured
                  .cast<Map>()
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: EdgeColors.accent.withOpacity(0.12),
                          border: Border.all(
                            color:
                                EdgeColors.accent.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${c['label'] ?? '—'} · ${c['timeframe'] ?? ''}',
                          style: AppTheme.sans(
                            size: 11,
                            color: EdgeColors.accentHi,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          if (err != null) ...[
            const SizedBox(height: 8),
            Text(
              err,
              style: AppTheme.mono(
                size: 11.5,
                color: EdgeColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
