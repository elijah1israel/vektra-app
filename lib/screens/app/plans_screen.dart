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
            title: Text('Trade Plans'),
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
          title: Text('Trade Plans'),
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
          ...closed.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HistoryRow(
                plan: p,
                onDelete: () => _deletePlan(p),
                statusChip: _statusChip(p['status'] as String? ?? ''),
                directionChip: _directionChipOrNull(
                    p['direction'] as String? ?? ''),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _deletePlan(Map<String, dynamic> plan) async {
    if (!await _confirm(
        "Permanently delete this plan? This can't be undone.")) {
      return;
    }
    try {
      final api = context.read<ApiClient>();
      await api.dio.delete('/plans/${plan['id']}/');
      setState(() {
        _plans = _plans?.where((p) => p['id'] != plan['id']).toList();
      });
      ToastMessenger.instance.success('Plan deleted.');
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    }
  }

  Widget? _directionChipOrNull(String direction) {
    if (direction.isEmpty || direction == 'none') return null;
    return _directionChip(direction);
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

/// Expand-on-tap history entry for closed / invalidated plans. Preview
/// row shows chips + first line of narrative; tapping opens the full
/// narrative, KV grid of levels, and a delete action.
class _HistoryRow extends StatefulWidget {
  const _HistoryRow({
    required this.plan,
    required this.onDelete,
    required this.statusChip,
    required this.directionChip,
  });

  final Map<String, dynamic> plan;
  final Future<void> Function() onDelete;
  final Widget statusChip;
  final Widget? directionChip;

  @override
  State<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<_HistoryRow> {
  bool _open = false;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final narrative = plan['narrative'] as String? ?? '';
    final invalidation = plan['invalidation'] as String? ?? '';
    final preview =
        (narrative.isNotEmpty ? narrative : invalidation)
            .split('\n')
            .first;
    final label = (plan['instrument'] as Map?)?['label'] as String? ?? '—';
    final outcome = _outcomeLabel(plan['outcome'] as String?);
    final tps = (plan['take_profits'] as List?) ?? const [];

    return EdgeCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  widget.statusChip,
                  const SizedBox(width: 8),
                  if (widget.directionChip != null) ...[
                    widget.directionChip!,
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: AppTheme.sans(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      )),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      preview.isEmpty ? '(no narrative)' : preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sans(
                        size: 11.5,
                        color: EdgeColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.expand_more,
                      color: EdgeColors.muted,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox.shrink()
                : Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: EdgeColors.white06),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (narrative.isNotEmpty) ...[
                          Text(
                            narrative,
                            style: AppTheme.sans(
                              size: 12.5,
                              color: EdgeColors.slate300,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        _kvGrid(context, [
                          if (outcome != null) ('Outcome', outcome),
                          if (plan['d1_bias'] != null)
                            ('D1 bias', plan['d1_bias'].toString()),
                          if (plan['direction'] != null &&
                              plan['direction'] != 'none')
                            (
                              'Direction',
                              (plan['direction'] as String).toUpperCase()
                            ),
                          if (plan['entry_price'] != null)
                            ('Entry', plan['entry_price'].toString()),
                          if (plan['stop_loss'] != null)
                            ('Stop loss', plan['stop_loss'].toString()),
                          if (tps.isNotEmpty)
                            (
                              'Take profits',
                              tps
                                  .map((tp) =>
                                      '${(tp as Map)['label']} ${tp['price']}${tp['hit'] == true ? ' ✓' : ''}')
                                  .join(' · ')
                            ),
                          if (invalidation.isNotEmpty)
                            ('Invalidation', invalidation),
                        ]),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: EdgeButton(
                            label: 'Delete',
                            icon: Icons.delete_outline,
                            kind: EdgeButtonKind.danger,
                            busy: _deleting,
                            onPressed: () async {
                              setState(() => _deleting = true);
                              await widget.onDelete();
                              if (mounted) {
                                setState(() => _deleting = false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String? _outcomeLabel(String? outcome) {
    switch (outcome) {
      case 'tp_hit':
        return 'Target hit';
      case 'stopped_out':
        return 'Stopped out';
      case 'manual_close':
        return 'Manual close';
      case 'missed':
        return 'Missed';
      case 'invalidated':
        return 'Invalidated';
      default:
        return null;
    }
  }

  Widget _kvGrid(BuildContext context, List<(String, String)> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (ctx, box) {
      final twoCol = box.maxWidth > 420;
      final children = rows.map(
        (r) => _KvCell(label: r.$1, value: r.$2),
      );
      if (!twoCol) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: c,
                  ))
              .toList(),
        );
      }
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: children
            .map((c) => SizedBox(
                  width: (box.maxWidth - 12) / 2,
                  child: c,
                ))
            .toList(),
      );
    });
  }
}

class _KvCell extends StatelessWidget {
  const _KvCell({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.sans(
            size: 10,
            weight: FontWeight.w600,
            color: EdgeColors.muted,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTheme.sans(
            size: 12.5,
            color: Colors.white,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
