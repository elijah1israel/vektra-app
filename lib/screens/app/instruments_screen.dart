import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../core/errors.dart';
import '../../models/instrument.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
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
            padding: const EdgeInsets.only(bottom: 10),
            child: _InstrumentCard(
              instrument: inst,
              sub: sub,
              running: running,
              onTap: () => context.push(
                '/instruments/${inst.id}/configure',
              ),
              onRun: sub == null || running
                  ? null
                  : () => _runNow(sub, inst.label),
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

/// One row in the Instruments list. Whole card taps into the configure
/// screen; subscribed rows get a discrete circular Run-now button on the
/// right. Not-subscribed rows just show a subtle chevron — no bulky
/// "Subscribe" button.
class _InstrumentCard extends StatelessWidget {
  const _InstrumentCard({
    required this.instrument,
    required this.sub,
    required this.running,
    required this.onTap,
    required this.onRun,
  });

  final Instrument instrument;
  final Subscription? sub;
  final bool running;
  final VoidCallback onTap;
  final VoidCallback? onRun;

  @override
  Widget build(BuildContext context) {
    final subscribed = sub != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: EdgeColors.card.withOpacity(0.82),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: subscribed
                  ? EdgeColors.accent.withOpacity(0.28)
                  : EdgeColors.white10,
            ),
          ),
          child: Row(
            children: [
              InstrumentIconBadge(
                label: instrument.label,
                symbol: instrument.symbol,
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instrument.label,
                      style: AppTheme.sans(
                        size: 14.5,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (subscribed)
                      _SubStatus(sub: sub!)
                    else
                      Text(
                        'Tap to subscribe',
                        style: AppTheme.sans(
                          size: 11.5,
                          color: EdgeColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (subscribed)
                _RunButton(running: running, onTap: onRun)
              else
                const Icon(
                  Icons.chevron_right,
                  color: EdgeColors.muted,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubStatus extends StatelessWidget {
  const _SubStatus({required this.sub});
  final Subscription sub;
  @override
  Widget build(BuildContext context) {
    final count = sub.schedules.length;
    final tf = sub.timeframes.isEmpty ? '—' : sub.timeframes.join('/');
    return Row(
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
        Flexible(
          child: Text(
            '$count ${count == 1 ? 'analysis/day' : 'analyses/day'}  ·  $tf',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.sans(
              size: 11.5,
              color: EdgeColors.slate300,
            ),
          ),
        ),
      ],
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({required this.running, required this.onTap});
  final bool running;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EdgeColors.accent.withOpacity(0.12),
              border: Border.all(
                color: EdgeColors.accent.withOpacity(0.4),
              ),
            ),
            child: running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(EdgeColors.accent),
                    ),
                  )
                : const Icon(
                    Icons.play_arrow_rounded,
                    color: EdgeColors.accent,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}
