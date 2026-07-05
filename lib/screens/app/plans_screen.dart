import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../core/errors.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/edge_buttons.dart';
import '../../widgets/edge_card.dart';
import '../../widgets/instrument_icon.dart';
import '../../widgets/page_header.dart';
import '../../widgets/spinner.dart';
import '../../widgets/toast.dart';

const _activeStatuses = {'awaiting_setup', 'armed', 'in_trade'};

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});
  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<Map<String, dynamic>>? _plans;
  int? _actingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/plans/');
      final data = res.data;
      final list = data is Map && data['results'] is List
          ? (data['results'] as List)
          : data as List;
      setState(() {
        _plans = list
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      });
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
      setState(() => _plans = []);
    }
  }

  Future<bool> _confirm(String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: EdgeColors.card,
            content: Text(msg,
                style: AppTheme.sans(
                    size: 13, color: EdgeColors.slate200)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _act(
    Map<String, dynamic> plan,
    String url,
    String successMsg, {
    Map<String, dynamic>? body,
    bool prompt = false,
  }) async {
    if (!await _confirm('Confirm this action on ${plan['instrument']?['label'] ?? ''}?')) {
      return;
    }
    setState(() => _actingId = plan['id'] as int);
    try {
      final api = context.read<ApiClient>();
      final res =
          await api.dio.post(url, data: body ?? {});
      final data = (res.data as Map).cast<String, dynamic>();
      setState(() {
        _plans = _plans
            ?.map((p) => p['id'] == plan['id'] ? data : p)
            .toList();
      });
      ToastMessenger.instance.success(successMsg);
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    if (user == null || !user.isBotOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/dashboard');
      });
      return const SizedBox.shrink();
    }
    if (_plans == null) return const PageSpinner();

    final active = _plans!
        .where((p) => _activeStatuses.contains(p['status']))
        .toList();
    final closed = _plans!
        .where((p) => !_activeStatuses.contains(p['status']))
        .toList();

    if (_plans!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            eyebrow: 'Owner tools',
            title: Text('D1 + H4 plans'),
            subtitle:
                'An endless cycle — every H4 close advances the plan one step.',
          ),
          const SizedBox(height: 20),
          EdgeCard(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Icon(Icons.explore_outlined,
                    size: 28, color: EdgeColors.muted),
                const SizedBox(height: 10),
                Text('No plans yet.',
                    style: AppTheme.sans(
                      size: 14,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    )),
                const SizedBox(height: 4),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Pick D1 + H4 Planner on one of your subscriptions and the first plan will spawn on the next scheduled H4-close run.',
                    textAlign: TextAlign.center,
                    style: AppTheme.sans(
                      size: 12,
                      color: EdgeColors.muted,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          eyebrow: 'Owner tools',
          title: Text('D1 + H4 plans'),
          subtitle:
              'Every H4 close advances the plan one step. While flat it holds a neutral watch with both directions mapped.',
        ),
        const SizedBox(height: 16),
        _sectionTitle('Active (${active.length})'),
        if (active.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text('No active plans right now.',
                style: AppTheme.sans(
                    size: 12.5, color: EdgeColors.muted)),
          )
        else
          ...active.map(_planCard),
        if (closed.isNotEmpty) ...[
          const SizedBox(height: 10),
          _sectionTitle('History (${closed.length})'),
          ...closed.map(_historyRow),
        ],
      ],
    );
  }

  Widget _sectionTitle(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          s.toUpperCase(),
          style: AppTheme.sans(
            size: 10.5,
            weight: FontWeight.w700,
            color: EdgeColors.muted,
            letterSpacing: 1.8,
          ),
        ),
      );

  Widget _planCard(Map<String, dynamic> plan) {
    final acting = _actingId == plan['id'];
    final status = plan['status'] as String? ?? '';
    final direction = plan['direction'] as String? ?? '';
    final instrument =
        (plan['instrument'] as Map?)?.cast<String, dynamic>() ?? {};
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EdgeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InstrumentIconBadge(
                  label: instrument['label'] as String? ?? '',
                  symbol: instrument['symbol'] as String? ?? '',
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    instrument['label'] as String? ?? 'Instrument',
                    style: AppTheme.sans(
                      size: 14,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                _statusChip(status),
                if (direction.isNotEmpty && direction != 'none') ...[
                  const SizedBox(width: 6),
                  _directionChip(direction),
                ],
              ],
            ),
            if ((plan['narrative'] as String?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Text(
                plan['narrative'] as String,
                style: AppTheme.sans(
                  size: 12.5,
                  color: EdgeColors.slate300,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status == 'armed')
                  EdgeButton(
                    label: 'Confirm fill',
                    icon: Icons.check,
                    kind: EdgeButtonKind.ghost,
                    busy: acting,
                    onPressed: () => _act(
                      plan,
                      '/plans/${plan['id']}/confirm_fill/',
                      'Fill confirmed — trade is yours now.',
                    ),
                  ),
                if (status == 'armed')
                  EdgeButton(
                    label: 'Mark missed',
                    icon: Icons.access_time,
                    kind: EdgeButtonKind.ghost,
                    busy: acting,
                    onPressed: () => _act(
                      plan,
                      '/plans/${plan['id']}/mark_missed/',
                      'Marked missed — not chased.',
                    ),
                  ),
                if (status == 'in_trade')
                  EdgeButton(
                    label: 'Stopped out',
                    icon: Icons.close,
                    kind: EdgeButtonKind.danger,
                    busy: acting,
                    onPressed: () => _act(
                      plan,
                      '/plans/${plan['id']}/close/',
                      'Stopped out — plan closed.',
                      body: {'reason': 'sl_hit'},
                    ),
                  ),
                if (status == 'in_trade')
                  EdgeButton(
                    label: 'Close manually',
                    icon: Icons.check_circle_outline,
                    kind: EdgeButtonKind.ghost,
                    busy: acting,
                    onPressed: () => _act(
                      plan,
                      '/plans/${plan['id']}/close/',
                      'Trade closed.',
                      body: {'reason': 'manual'},
                    ),
                  ),
                EdgeButton(
                  label: 'Invalidate',
                  icon: Icons.block,
                  kind: EdgeButtonKind.danger,
                  busy: acting,
                  onPressed: () => _act(
                    plan,
                    '/plans/${plan['id']}/invalidate/',
                    'Plan invalidated — fresh neutral watch drafting.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyRow(Map<String, dynamic> plan) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EdgeCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _statusChip(plan['status'] as String? ?? ''),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                (plan['instrument'] as Map?)?['label'] as String? ??
                    '—',
                style: AppTheme.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              plan['outcome']?.toString() ?? '',
              style: AppTheme.sans(
                size: 11,
                color: EdgeColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final map = <String, (Color, String)>{
      'awaiting_setup': (
        const Color(0xFF7DD3FC),
        'Neutral watch',
      ),
      'armed': (const Color(0xFFFCD34D), 'Armed'),
      'in_trade': (const Color(0xFF6EE7B7), 'In trade'),
      'closed': (const Color(0xFFCBD5E1), 'Closed'),
      'invalidated': (const Color(0xFFFDA4AF), 'Invalidated'),
    };
    final (color, label) =
        map[status] ?? map['awaiting_setup']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTheme.sans(
          size: 10.5,
          weight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _directionChip(String direction) {
    final buy = direction == 'buy';
    final color = buy ? EdgeColors.accent : EdgeColors.danger;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        direction.toUpperCase(),
        style: AppTheme.sans(
          size: 10.5,
          weight: FontWeight.w700,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
