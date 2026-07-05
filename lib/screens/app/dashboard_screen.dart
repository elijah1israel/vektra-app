import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../core/schedule_math.dart';
import '../../models/instrument.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/edge_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/instrument_icon.dart';
import '../../widgets/sessions_card.dart';
import '../../widgets/spinner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List<Subscription> _subs = [];
  Map<String, dynamic>? _usage;
  Timer? _rebaseTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Re-base the "next run" once a minute so a missed firing rolls over
    // even without a manual refresh; the digits inside the card tick
    // every second on their own.
    _rebaseTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _rebaseTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      final r = await Future.wait([
        api.dio.get('/subscriptions/'),
        api.dio.get('/runs/usage/'),
      ]);
      setState(() {
        _subs = (r[0].data as List)
            .map((e) =>
                Subscription.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        _usage = (r[1].data as Map).cast<String, dynamic>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Trading late';
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const PageSpinner();
    final user = context.watch<AuthState>().user;
    final firstName =
        user?.fullName?.split(' ').first ?? 'trader';
    final cap = (_usage?['cap'] as num?)?.toInt() ?? 6;
    final used = (_usage?['used'] as num?)?.toInt() ?? 0;
    final exhausted = used >= cap && cap < 100000;
    final next = computeNextRun(_subs);

    // AppShell already wraps every screen in a SingleChildScrollView, so a
    // Column here gets its natural bounded intrinsic height. A ListView
    // would have been unbounded in that parent and rendered nothing.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          greeting: _greeting(),
          firstName: firstName,
          accountType: user?.accountType,
          accountSize: user?.accountSize,
        ),
        const SizedBox(height: 20),
        _NextRunCard(next: next, exhausted: exhausted),
        const SizedBox(height: 14),
        _UsageCard(used: used, cap: cap),
        const SizedBox(height: 14),
        const SessionsCard(),
        const SizedBox(height: 18),
        _InstrumentsBlock(subs: _subs),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.greeting,
    required this.firstName,
    required this.accountType,
    required this.accountSize,
  });
  final String greeting;
  final String firstName;
  final String? accountType;
  final int? accountSize;

  @override
  Widget build(BuildContext context) {
    final label = accountType == null
        ? 'Overview'
        : '${accountType == 'propfirm' ? 'Prop firm' : 'Live'}'
            '${accountSize != null ? ' · \$$accountSize' : ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: AppTheme.display(
              size: 28,
              weight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.1,
            ),
            children: [
              TextSpan(text: '$greeting, '),
              TextSpan(
                text: firstName,
                style: const TextStyle(color: EdgeColors.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Here's what's next across your subscriptions.",
          style: AppTheme.sans(
            size: 13,
            color: EdgeColors.muted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Ticking countdown to the next scheduled analysis. Rebuilds itself once
/// a second so days/hours/minutes/seconds all update smoothly. Uses
/// [computeNextRun] which walks the user's subscriptions with IANA-tz
/// precision.
class _NextRunCard extends StatefulWidget {
  const _NextRunCard({required this.next, required this.exhausted});
  final NextRun? next;
  final bool exhausted;

  @override
  State<_NextRunCard> createState() => _NextRunCardState();
}

class _NextRunCardState extends State<_NextRunCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    if (widget.next != null) {
      _tick = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (mounted) setState(() {});
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant _NextRunCard old) {
    super.didUpdateWidget(old);
    if (widget.next != null && _tick == null) {
      _tick = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (mounted) setState(() {});
        },
      );
    } else if (widget.next == null) {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.next;
    if (next == null) {
      return EdgeCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: EdgeColors.muted.withOpacity(0.1),
                border: Border.all(
                  color: EdgeColors.muted.withOpacity(0.2),
                ),
              ),
              child:
                  const Icon(Icons.timer_outlined, color: EdgeColors.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next scheduled analysis',
                    style: AppTheme.sans(
                      size: 11,
                      color: EdgeColors.muted,
                      weight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No active schedules yet. Configure analysis times on any instrument to see the next firing here.',
                    style: AppTheme.sans(
                      size: 12.5,
                      color: EdgeColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final ms = next.at.difference(now).inMilliseconds.clamp(0, 1 << 62);
    final totalSec = ms ~/ 1000;
    final days = totalSec ~/ 86400;
    final hours = (totalSec % 86400) ~/ 3600;
    final minutes = (totalSec % 3600) ~/ 60;
    final seconds = totalSec % 60;
    final localTime = DateFormat('EEE HH:mm').format(next.at.toLocal());

    return EdgeCard(
      borderColor: EdgeColors.accent.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Eyebrow('Next scheduled analysis'),
              const Spacer(),
              InstrumentIconBadge(
                label: next.subscription.instrument.label,
                symbol: next.subscription.instrument.symbol,
                size: 22,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  next.subscription.instrument.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.sans(
                    size: 12,
                    color: Colors.white,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (days > 0) _Digit(value: days, unit: 'd'),
              _Digit(value: hours, unit: 'h'),
              _Digit(value: minutes, unit: 'm'),
              _Digit(value: seconds, unit: 's'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.exhausted
                ? 'Fires $localTime your time. Daily cap reached — this analysis will be skipped until 00:00 UTC.'
                : 'Fires $localTime your time.',
            style: AppTheme.sans(
              size: 11.5,
              color: widget.exhausted
                  ? EdgeColors.danger
                  : EdgeColors.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Digit extends StatelessWidget {
  const _Digit({required this.value, required this.unit});
  final int value;
  final String unit;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: AppTheme.mono(
              size: 28,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            unit,
            style: AppTheme.sans(
              size: 11,
              color: EdgeColors.muted,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.used, required this.cap});
  final int used;
  final int cap;

  @override
  Widget build(BuildContext context) {
    const threshold = 100000;
    final unlimited = cap >= threshold;
    final remaining = (cap - used).clamp(0, cap);
    final pct = unlimited ? 0 : ((used / cap) * 100).clamp(0, 100).round();
    final exhausted = !unlimited && remaining == 0;
    final color = exhausted ? EdgeColors.danger : EdgeColors.accent;
    return EdgeCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.24)),
            ),
            child: Icon(Icons.bolt, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Eyebrow('Daily analyses')),
                    Text(
                      unlimited
                          ? 'Unlimited · $used today'
                          : '$remaining / $cap left',
                      style: AppTheme.sans(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 6,
                    color: EdgeColors.border,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct / 100.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: exhausted
                                ? const [
                                    EdgeColors.danger,
                                    EdgeColors.danger,
                                  ]
                                : const [
                                    EdgeColors.accentDim,
                                    EdgeColors.accentHi,
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstrumentsBlock extends StatelessWidget {
  const _InstrumentsBlock({required this.subs});
  final List<Subscription> subs;

  @override
  Widget build(BuildContext context) {
    return EdgeCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Text(
                  'Your instruments',
                  style: AppTheme.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/instruments'),
                  child: Row(
                    children: [
                      Text('Manage',
                          style: AppTheme.sans(
                            size: 12,
                            weight: FontWeight.w600,
                            color: EdgeColors.accent,
                          )),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward,
                          size: 13, color: EdgeColors.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: EdgeColors.white06, height: 1),
          if (subs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: EdgeColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: EdgeColors.accent.withOpacity(0.2),
                      ),
                    ),
                    child: const Icon(Icons.candlestick_chart_outlined,
                        color: EdgeColors.accent, size: 22),
                  ),
                  const SizedBox(height: 14),
                  Text('No instruments yet',
                      style: AppTheme.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    'Subscribe to a market and the bot will start delivering trade plans.',
                    textAlign: TextAlign.center,
                    style: AppTheme.sans(
                        size: 12.5, color: EdgeColors.muted),
                  ),
                ],
              ),
            )
          else
            ...subs.map(
              (s) => InkWell(
                onTap: () => context.push('/instruments'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: EdgeColors.white06),
                    ),
                  ),
                  child: Row(
                    children: [
                      InstrumentIconBadge(
                        label: s.instrument.label,
                        symbol: s.instrument.symbol,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.instrument.label,
                                style: AppTheme.sans(
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                  color: Colors.white,
                                )),
                            const SizedBox(height: 3),
                            Text(
                              '${s.schedules.length} ${s.schedules.length == 1 ? 'analysis/day' : 'analyses/day'}',
                              style: AppTheme.sans(
                                size: 11.5,
                                color: EdgeColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 14, color: EdgeColors.muted),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
