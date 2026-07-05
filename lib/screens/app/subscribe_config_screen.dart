import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../core/errors.dart';
import '../../models/instrument.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/edge_buttons.dart';
import '../../widgets/edge_card.dart';
import '../../widgets/edge_input.dart';
import '../../widgets/instrument_icon.dart';
import '../../widgets/spinner.dart';
import '../../widgets/toast.dart';

class _Strategy {
  const _Strategy(this.value, this.label, this.icon, this.hint,
      {this.ownerOnly = false});
  final String value;
  final String label;
  final IconData icon;
  final String hint;
  final bool ownerOnly;
}

const _strategies = <_Strategy>[
  _Strategy('smc', 'Smart Money', Icons.grid_view_rounded,
      'Order blocks, liquidity sweeps, fair value gaps and structure shifts.'),
  _Strategy('ict', 'ICT', Icons.center_focus_strong_outlined,
      'Killzones, FVGs, liquidity pools and optimal trade entry.'),
  _Strategy(
      'supply_demand',
      'Supply & Demand',
      Icons.layers_outlined,
      'Fresh imbalance zones and base-rally-base origins.'),
  _Strategy('price_action', 'Price Action', Icons.show_chart,
      'Support/resistance, candlestick patterns and trendlines.'),
  _Strategy('trend', 'Trend Following', Icons.trending_up,
      'Trade with the dominant trend, entering on pullbacks.'),
  _Strategy('breakout', 'Breakout', Icons.bolt_outlined,
      'Range/structure breaks with a confirmation retest.'),
  _Strategy('versatile', 'Versatile', Icons.auto_awesome_outlined,
      'The bot picks whichever methodology fits the chart best.'),
  _Strategy(
    'd1_h4_planner',
    'D1 + H4 Planner',
    Icons.explore_outlined,
    'Stateful plan advanced one H4 close at a time.',
    ownerOnly: true,
  ),
];

const _timeframes = ['W1', 'D1', 'H4', 'H1', 'M15', 'M5'];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _rrPresets = [2, 3, 4, 5];
const _orderTypes = [
  ('versatile', 'Versatile'),
  ('limit', 'Limit'),
  ('market', 'Market'),
  ('stop', 'Stop'),
];

class SubscribeConfigScreen extends StatefulWidget {
  const SubscribeConfigScreen({super.key, required this.instrumentId});
  final int instrumentId;
  @override
  State<SubscribeConfigScreen> createState() =>
      _SubscribeConfigScreenState();
}

class _SubscribeConfigScreenState extends State<SubscribeConfigScreen> {
  bool _loading = true;
  bool _saving = false;
  Instrument? _instrument;
  Subscription? _existingSub;
  Subscription? _otherSub;

  List<String> _timeframesSel = ['D1', 'H4'];
  final Set<int> _daysSel = {};
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  int _minRr = 3;
  String _tpMode = 'single';
  String _orderType = 'versatile';
  String _strategy = 'smc';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      final r = await Future.wait([
        api.dio.get('/instruments/'),
        api.dio.get('/subscriptions/'),
      ]);
      final insts = (r[0].data as List)
          .map((e) =>
              Instrument.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      final subs = (r[1].data as List)
          .map((e) => Subscription.fromJson(
              (e as Map).cast<String, dynamic>()))
          .toList();
      Instrument? found;
      for (final i in insts) {
        if (i.id == widget.instrumentId) found = i;
      }
      Subscription? existing;
      Subscription? other;
      for (final s in subs) {
        if (s.instrument.id == widget.instrumentId) {
          existing = s;
        } else {
          other ??= s;
        }
      }
      setState(() {
        _instrument = found;
        _existingSub = existing;
        _otherSub = other;
        if (existing != null) _applyFromSub(existing);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ToastMessenger.instance.error(describeError(e));
    }
  }

  void _applyFromSub(Subscription s) {
    _timeframesSel =
        s.timeframes.isEmpty ? const ['D1', 'H4'] : s.timeframes.take(2).toList();
    _minRr = (s.minRr ?? 3).round();
    _tpMode = s.tpMode ?? 'single';
    _orderType = s.orderType ?? 'versatile';
    _strategy = s.strategy ?? 'smc';
    if (s.schedules.isNotEmpty) {
      final times = <TimeOfDay>[];
      final days = <int>{};
      for (final sc in s.schedules) {
        times.add(TimeOfDay(hour: sc.hour, minute: sc.minute));
        days.addAll(sc.days);
      }
      _times = times.take(6).toList();
      if (_times.isEmpty) _times = [const TimeOfDay(hour: 8, minute: 0)];
      _daysSel
        ..clear()
        ..addAll(days);
    }
  }

  Future<void> _save() async {
    if (_timeframesSel.isEmpty) {
      ToastMessenger.instance
          .error('Select at least one chart timeframe.');
      return;
    }
    if (_times.isEmpty) {
      ToastMessenger.instance.error('Add at least one analysis time.');
      return;
    }
    final schedules = _times
        .map((t) => {
              'hour': t.hour,
              'minute': t.minute,
              'days': _daysSel.toList()..sort(),
            })
        .toList();
    final payload = {
      'timeframes': _timeframesSel,
      'min_rr': _minRr,
      'tp_mode': _tpMode,
      'order_type': _orderType,
      'strategy': _strategy,
      'schedules': schedules,
    };
    setState(() => _saving = true);
    try {
      final api = context.read<ApiClient>();
      if (_existingSub != null) {
        await api.dio.patch(
          '/subscriptions/${_existingSub!.id}/',
          data: payload,
        );
        ToastMessenger.instance
            .success('${_instrument!.label} settings saved.');
      } else {
        if (_otherSub != null) {
          await api.dio.delete('/subscriptions/${_otherSub!.id}/');
        }
        await api.dio.post('/subscriptions/', data: {
          'instrument_id': _instrument!.id,
          ...payload,
        });
        ToastMessenger.instance.success(
            _otherSub != null
                ? 'Switched to ${_instrument!.label}.'
                : 'Subscribed to ${_instrument!.label}.');
      }
      if (mounted) context.go('/instruments');
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _unsubscribe() async {
    if (_existingSub == null) return;
    setState(() => _saving = true);
    try {
      final api = context.read<ApiClient>();
      await api.dio.delete('/subscriptions/${_existingSub!.id}/');
      ToastMessenger.instance
          .info('Unsubscribed from ${_instrument!.label}.');
      if (mounted) context.go('/instruments');
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _unfollow() async {
    setState(() => _saving = true);
    try {
      final api = context.read<ApiClient>();
      await api.dio.delete('/auth/follows/me/');
      await context.read<AuthState>().refreshProfile();
      ToastMessenger.instance
          .info('Sync ended. Your own setup is back in control.');
      if (mounted) context.go('/instruments');
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const PageSpinner();
    if (_instrument == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Text('Instrument not found.',
                  style: AppTheme.sans(
                      size: 13, color: EdgeColors.muted)),
              const SizedBox(height: 12),
              EdgeButton(
                label: 'Back to instruments',
                kind: EdgeButtonKind.ghost,
                onPressed: () => context.go('/instruments'),
              ),
            ],
          ),
        ),
      );
    }
    final following =
        context.watch<AuthState>().user?.following;
    final isOwner =
        context.watch<AuthState>().user?.isBotOwner ?? false;
    final isPlanner = _strategy == 'd1_h4_planner';
    final activeStrategy =
        _strategies.firstWhere((s) => s.value == _strategy);
    final readOnly = following != null;

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
            InstrumentIconBadge(
              label: _instrument!.label,
              symbol: _instrument!.symbol,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_instrument!.label,
                  style: AppTheme.display(
                    size: 22,
                    weight: FontWeight.w700,
                    letterSpacing: -0.4,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (following != null)
          _Banner(
            icon: Icons.link,
            text:
                'Synced from ${following.fullName ?? 'a trader'}. Their setup is mirrored below — read-only.',
          ),
        if (following == null && _otherSub != null)
          _Banner(
            icon: Icons.info_outline,
            text:
                "You're currently subscribed to ${_otherSub!.instrument.label}. Subscribing here will end that.",
            action: EdgeButton(
              label: "Import ${_otherSub!.instrument.label}'s settings",
              icon: Icons.download,
              kind: EdgeButtonKind.ghost,
              onPressed: () {
                _applyFromSub(_otherSub!);
                setState(() {});
                ToastMessenger.instance.success(
                    'Imported settings from ${_otherSub!.instrument.label}.');
              },
            ),
          ),
        _Section(
          title: 'Strategy',
          desc: activeStrategy.hint,
          child: AbsorbPointer(
            absorbing: readOnly,
            child: _StrategyDropdown(
              value: _strategy,
              isOwner: isOwner,
              onChanged: (v) => setState(() => _strategy = v),
            ),
          ),
        ),
        _Section(
          title: 'Charts to analyse',
          desc: isPlanner
              ? 'Fixed by the D1 + H4 Planner — D1 sets bias, H4 executes.'
              : 'Pick up to 2 timeframes the bot captures and reads.',
          right: isPlanner
              ? null
              : Text('${_timeframesSel.length} / 2',
                  style: AppTheme.sans(
                      size: 11, color: EdgeColors.muted)),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (isPlanner ? ['D1', 'H4'] : _timeframes)
                .map((tf) {
              final active = _timeframesSel.contains(tf);
              return _Chip(
                label: tf,
                active: active,
                disabled: isPlanner ||
                    readOnly ||
                    (!active && _timeframesSel.length >= 2),
                onTap: () {
                  setState(() {
                    if (active) {
                      _timeframesSel = List.of(_timeframesSel)
                        ..remove(tf);
                    } else if (_timeframesSel.length < 2) {
                      _timeframesSel = List.of(_timeframesSel)..add(tf);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        _Section(
          title: 'Schedule',
          desc: _daysSel.isEmpty
              ? 'Analyses every day.'
              : 'Analyses on the selected days.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_days.length, (i) {
                  final active = _daysSel.contains(i);
                  return _Chip(
                    label: _days[i],
                    active: active,
                    disabled: readOnly,
                    onTap: () {
                      setState(() {
                        if (active) {
                          _daysSel.remove(i);
                        } else {
                          _daysSel.add(i);
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('ANALYSIS TIMES',
                      style: AppTheme.label()),
                  const Spacer(),
                  Text('${_times.length} / 6',
                      style: AppTheme.sans(
                          size: 11, color: EdgeColors.muted)),
                ],
              ),
              const SizedBox(height: 8),
              ..._times.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: EdgeColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: readOnly
                              ? null
                              : () async {
                                  final res = await showTimePicker(
                                    context: context,
                                    initialTime: e.value,
                                    builder: (ctx, child) => Theme(
                                      data: Theme.of(ctx),
                                      child: child!,
                                    ),
                                  );
                                  if (res != null) {
                                    setState(() =>
                                        _times[e.key] = res);
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: EdgeColors.surface
                                  .withOpacity(0.7),
                              border:
                                  Border.all(color: EdgeColors.white08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              e.value.format(context),
                              style: AppTheme.sans(
                                size: 13.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: (_times.length == 1 || readOnly)
                            ? null
                            : () => setState(
                                () => _times.removeAt(e.key)),
                        icon: const Icon(Icons.delete_outline,
                            size: 16),
                        color: EdgeColors.muted,
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
              EdgeButton(
                label: 'Add analysis time',
                icon: Icons.add,
                kind: EdgeButtonKind.ghost,
                fullWidth: true,
                onPressed: (readOnly || _times.length >= 6)
                    ? null
                    : () => setState(() => _times.add(
                          const TimeOfDay(hour: 12, minute: 0),
                        )),
              ),
            ],
          ),
        ),
        if (!isPlanner)
          _Section(
            title: 'Minimum R:R',
            desc: 'The smallest reward-to-risk a setup must offer.',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _rrPresets.map((rr) {
                return _Chip(
                  label: '1:$rr',
                  active: _minRr == rr,
                  disabled: readOnly,
                  onTap: () => setState(() => _minRr = rr),
                );
              }).toList(),
            ),
          ),
        _Section(
          title: 'Take profit',
          desc: 'How many targets each setup should give.',
          child: Row(
            children: [
              Expanded(
                child: _Chip(
                  label: 'Single target',
                  active: _tpMode == 'single',
                  disabled: readOnly,
                  onTap: () => setState(() => _tpMode = 'single'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Chip(
                  label: 'Multiple (TP1–3)',
                  active: _tpMode == 'multiple',
                  disabled: readOnly,
                  onTap: () => setState(() => _tpMode = 'multiple'),
                ),
              ),
            ],
          ),
        ),
        if (!isPlanner)
          _Section(
            title: 'Order type',
            desc: _orderHint(_orderType),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.6,
              children: _orderTypes.map((o) {
                return _Chip(
                  label: o.$2,
                  active: _orderType == o.$1,
                  disabled: readOnly,
                  onTap: () => setState(() => _orderType = o.$1),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 18),
        if (following != null)
          EdgeButton(
            label: 'Unfollow & take back control',
            fullWidth: true,
            busy: _saving,
            onPressed: _unfollow,
          )
        else
          Row(
            children: [
              if (_existingSub != null) ...[
                EdgeButton(
                  label: 'Unsubscribe',
                  kind: EdgeButtonKind.danger,
                  onPressed: _saving ? null : _unsubscribe,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: EdgeButton(
                  label:
                      _existingSub != null ? 'Save settings' : 'Subscribe',
                  fullWidth: true,
                  busy: _saving,
                  onPressed: _save,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _orderHint(String v) => switch (v) {
        'versatile' =>
          'The bot picks the best order type (market, limit or stop) per setup.',
        'limit' =>
          'Resting orders at a better price the market must pull back to.',
        'market' => 'Enter at the current price when a setup is found.',
        'stop' =>
          'Breakout entries that trigger as price moves through a level.',
        _ => '',
      };
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.desc,
    required this.child,
    this.right,
  });
  final String title;
  final String desc;
  final Widget child;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
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
                if (right != null) right!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.disabled = false,
  });
  final String label;
  final bool active;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
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
            textAlign: TextAlign.center,
            style: AppTheme.sans(
              size: 12.5,
              weight: FontWeight.w600,
              color: active ? EdgeColors.accentHi : EdgeColors.slate300,
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EdgeCard(
        borderColor: EdgeColors.accent.withOpacity(0.3),
        tint: EdgeColors.accent.withOpacity(0.04),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: EdgeColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTheme.sans(
                      size: 12.5,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 12),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrategyDropdown extends StatelessWidget {
  const _StrategyDropdown({
    required this.value,
    required this.isOwner,
    required this.onChanged,
  });
  final String value;
  final bool isOwner;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final visible =
        _strategies.where((s) => !s.ownerOnly || isOwner).toList();
    final selected =
        visible.firstWhere((s) => s.value == value, orElse: () => visible.first);
    return PopupMenuButton<String>(
      color: EdgeColors.card,
      offset: const Offset(0, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: EdgeColors.white10),
      ),
      itemBuilder: (ctx) => visible
          .map((s) => PopupMenuItem<String>(
                value: s.value,
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: EdgeColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(s.icon,
                          size: 15, color: EdgeColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s.label,
                          style: AppTheme.sans(
                            size: 13,
                            weight: FontWeight.w600,
                            color: s.value == value
                                ? EdgeColors.accent
                                : Colors.white,
                          )),
                    ),
                  ],
                ),
              ))
          .toList(),
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: EdgeColors.white10),
          borderRadius: BorderRadius.circular(14),
          color: EdgeColors.surface.withOpacity(0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EdgeColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: EdgeColors.accent.withOpacity(0.3),
                ),
              ),
              child: Icon(selected.icon,
                  size: 16, color: EdgeColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected.label,
                style: AppTheme.sans(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
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

// Unused but kept for completeness (avoid removing to keep imports honest)
// ignore: unused_element
const _unused = EdgeInput;
// ignore: unused_element
const _unusedFmt = FilteringTextInputFormatter;
