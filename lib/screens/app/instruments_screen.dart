import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../core/errors.dart';
import '../../models/instrument.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/edge_buttons.dart';
import '../../widgets/edge_card.dart';
import '../../widgets/instrument_icon.dart';
import '../../widgets/page_header.dart';
import '../../widgets/spinner.dart';
import '../../widgets/toast.dart';

class InstrumentsScreen extends StatefulWidget {
  const InstrumentsScreen({super.key});
  @override
  State<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  bool _loading = true;
  List<Instrument> _instruments = [];
  List<Subscription> _subs = [];
  final Map<int, bool> _running = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      final results = await Future.wait([
        api.dio.get('/instruments/'),
        api.dio.get('/subscriptions/'),
      ]);
      setState(() {
        _instruments = (results[0].data as List)
            .map((e) => Instrument.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList();
        _subs = (results[1].data as List)
            .map((e) => Subscription.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ToastMessenger.instance.error(describeError(e));
    }
  }

  Subscription? _subFor(int id) =>
      _subs.where((s) => s.instrument.id == id).cast<Subscription?>().firstOrNull;

  Future<void> _runNow(Subscription sub, String label) async {
    setState(() => _running[sub.id] = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.post('/subscriptions/${sub.id}/run_now/');
      final runId = (res.data as Map)['id'];
      ToastMessenger.instance.info('Analysing $label…');
      _pollRun(runId as int, sub.id, label);
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
      setState(() => _running[sub.id] = false);
    }
  }

  Future<void> _pollRun(int runId, int subId, String label) async {
    final started = DateTime.now();
    Future<void> tick() async {
      if (!mounted) return;
      try {
        final api = context.read<ApiClient>();
        final res = await api.dio.get('/runs/$runId/');
        final status = (res.data as Map)['status'];
        if (status == 'success') {
          ToastMessenger.instance
              .success('$label trade plan ready — sent to your Telegram.');
          setState(() => _running[subId] = false);
          return;
        }
        if (status == 'failed') {
          ToastMessenger.instance
              .error('$label analysis failed. Please try again shortly.');
          setState(() => _running[subId] = false);
          return;
        }
      } catch (_) {}
      if (DateTime.now().difference(started) >
          const Duration(minutes: 4)) {
        setState(() => _running[subId] = false);
        return;
      }
      Timer(const Duration(seconds: 4), tick);
    }

    Timer(const Duration(seconds: 3), tick);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const PageSpinner();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          eyebrow: 'Markets',
          title: Text('Instruments'),
          subtitle:
              'Subscribe and configure how the bot analyses each market. Trade plans are delivered to your paired Telegram.',
        ),
        const SizedBox(height: 18),
        ..._instruments.map((inst) {
          final sub = _subFor(inst.id);
          final running = _running[sub?.id] ?? false;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EdgeCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InstrumentIconBadge(
                    label: inst.label,
                    symbol: inst.symbol,
                    size: 44,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inst.label,
                            style: AppTheme.sans(
                              size: 14,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            )),
                        if (sub != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: EdgeColors.accent,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('Active',
                                  style: AppTheme.sans(
                                    size: 11,
                                    color: EdgeColors.accent,
                                    weight: FontWeight.w600,
                                  )),
                              const SizedBox(width: 8),
                              Text(
                                '${sub.schedules.length} ${sub.schedules.length == 1 ? 'analysis/day' : 'analyses/day'}',
                                style: AppTheme.sans(
                                  size: 11,
                                  color: EdgeColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (sub != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EdgeButton(
                          label: running ? 'Analysing…' : 'Run',
                          icon: running ? null : Icons.play_arrow,
                          kind: EdgeButtonKind.ghost,
                          busy: running,
                          onPressed: running
                              ? null
                              : () => _runNow(sub, inst.label),
                        ),
                        const SizedBox(width: 6),
                        EdgeButton(
                          label: 'Configure',
                          icon: Icons.tune,
                          kind: EdgeButtonKind.ghost,
                          onPressed: () => context.push(
                            '/instruments/${inst.id}/configure',
                          ),
                        ),
                      ],
                    )
                  else
                    EdgeButton(
                      label: 'Subscribe',
                      icon: Icons.add,
                      onPressed: () => context
                          .push('/instruments/${inst.id}/configure'),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
