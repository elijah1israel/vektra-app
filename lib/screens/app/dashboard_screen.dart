import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../models/instrument.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/edge_buttons.dart';
import '../../widgets/edge_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/instrument_icon.dart';
import '../../widgets/page_header.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      final results = await Future.wait([
        api.dio.get('/subscriptions/'),
        api.dio.get('/runs/usage/'),
      ]);
      final subs = (results[0].data as List)
          .map((e) => Subscription.fromJson(
              (e as Map).cast<String, dynamic>()))
          .toList();
      setState(() {
        _subs = subs;
        _usage = (results[1].data as Map).cast<String, dynamic>();
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
    final firstName = user?.fullName?.split(' ').first ?? 'trader';
    final accountLabel = () {
      if (user?.accountType == null) return 'Overview';
      final type = user!.accountType == 'propfirm' ? 'Prop firm' : 'Live';
      if (user.accountSize == null) return type;
      return '$type · \$${user.accountSize}';
    }();
    final cap = (_usage?['cap'] as num?)?.toInt() ?? 6;
    final used = (_usage?['used'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: accountLabel,
          title: RichText(
            text: TextSpan(
              style: AppTheme.display(
                size: 28,
                weight: FontWeight.w700,
                letterSpacing: -0.6,
                height: 1.15,
              ),
              children: [
                TextSpan(text: '${_greeting()}, '),
                TextSpan(
                  text: firstName,
                  style: const TextStyle(color: EdgeColors.accent),
                ),
              ],
            ),
          ),
          subtitle:
              'Your trading-signal command center — instruments and schedules at a glance.',
          trailing: EdgeButton(
            label: 'Browse instruments',
            icon: Icons.add,
            onPressed: () => context.push('/instruments'),
          ),
        ),
        const SizedBox(height: 22),
        _UsageCard(used: used, cap: cap),
        const SizedBox(height: 14),
        const SessionsCard(),
        const SizedBox(height: 18),
        EdgeCard(
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
                                  color: EdgeColors.accent)),
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
              if (_subs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              EdgeColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                EdgeColors.accent.withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(Icons.add,
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
                      const SizedBox(height: 18),
                      EdgeButton(
                        label: 'Add an instrument',
                        icon: Icons.add,
                        onPressed: () => context.push('/instruments'),
                      ),
                    ],
                  ),
                )
              else
                ..._subs.map(
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
        ),
      ],
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
            width: 46,
            height: 46,
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
                    Expanded(
                      child: const Eyebrow('Daily analyses'),
                    ),
                    Text(
                      unlimited
                          ? 'Unlimited · $used today'
                          : '$remaining / $cap left',
                      style: AppTheme.sans(
                        size: 13,
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
