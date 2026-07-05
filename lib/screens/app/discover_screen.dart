import 'dart:async';
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
import '../../widgets/edge_input.dart';
import '../../widgets/instrument_icon.dart';
import '../../widgets/page_header.dart';
import '../../widgets/spinner.dart';
import '../../widgets/toast.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _leaders = [];
  bool _loading = true;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final url = q.isEmpty
          ? '/auth/leaders/'
          : '/auth/leaders/?q=${Uri.encodeQueryComponent(q)}';
      final res = await api.dio.get(url);
      final list = (res.data as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      setState(() {
        _leaders = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ToastMessenger.instance.error(describeError(e));
    }
  }

  Future<void> _follow(Map<String, dynamic> leader) async {
    setState(() => _busyId = leader['id'] as int);
    try {
      final api = context.read<ApiClient>();
      await api.dio
          .post('/auth/follows/me/', data: {'user_id': leader['id']});
      await context.read<AuthState>().refreshProfile();
      ToastMessenger.instance.success(
          "You're now synced with ${leader['full_name'] ?? 'this trader'}.");
      if (mounted) context.push('/instruments');
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _unfollow() async {
    setState(() => _busyId = -1);
    try {
      final api = context.read<ApiClient>();
      await api.dio.delete('/auth/follows/me/');
      await context.read<AuthState>().refreshProfile();
      ToastMessenger.instance
          .info('Sync ended. Your own setup is back in control.');
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  String _initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final a = parts.isNotEmpty ? parts[0][0] : '';
    final b = parts.length > 1 ? parts[1][0] : '';
    final s = (a + b).toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthState>().user;
    final followingId = me?.following?.id;
    final visible = _leaders.where((l) => l['id'] != me?.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          eyebrow: 'Discover',
          title: Text('Sync with a trader'),
          subtitle:
              "Pick someone's setup and your subscription mirrors theirs — same instrument, same schedule, same trade plans.",
        ),
        const SizedBox(height: 16),
        if (me?.following != null) ...[
          EdgeCard(
            borderColor: EdgeColors.accent.withOpacity(0.3),
            tint: EdgeColors.accent.withOpacity(0.04),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: EdgeColors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "You're synced with ${me!.following!.fullName ?? 'a trader'}${me.following!.instrumentLabel != null ? ' on ${me.following!.instrumentLabel}' : ''}.",
                    style: AppTheme.sans(
                        size: 12.5, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                EdgeButton(
                  label: 'Unfollow',
                  kind: EdgeButtonKind.ghost,
                  busy: _busyId == -1,
                  onPressed: _unfollow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        EdgeInput(
          controller: _search,
          hint: 'Search by name…',
          leadingIcon: Icons.search,
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 250),
                () => _load(v));
          },
        ),
        const SizedBox(height: 12),
        if (_loading)
          const PageSpinner()
        else if (visible.isEmpty)
          EdgeCard(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                _search.text.isEmpty
                    ? 'No discoverable traders yet — be the first to share your setup.'
                    : 'No traders match "${_search.text}".',
                style: AppTheme.sans(size: 13, color: EdgeColors.muted),
              ),
            ),
          )
        else
          ...visible.map((leader) {
            final isCurrent = leader['id'] == followingId;
            final blocked = followingId != null && !isCurrent;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EdgeCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: EdgeColors.accent,
                      ),
                      child: Text(
                        _initials(leader['full_name'] as String?),
                        style: AppTheme.sans(
                          size: 13,
                          weight: FontWeight.w700,
                          color: EdgeColors.bg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(leader['full_name'] as String? ?? 'Trader',
                              style: AppTheme.sans(
                                size: 14,
                                weight: FontWeight.w600,
                                color: Colors.white,
                              )),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment:
                                WrapCrossAlignment.center,
                            children: [
                              if (leader['instrument_label'] != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InstrumentIconBadge(
                                      label:
                                          leader['instrument_label'] as String,
                                      symbol:
                                          (leader['instrument_symbol'] as String?) ?? '',
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      leader['instrument_label'] as String,
                                      style: AppTheme.sans(
                                        size: 11,
                                        color: EdgeColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              if ((leader['timeframes']
                                          as List<dynamic>?)
                                      ?.isNotEmpty ??
                                  false)
                                Text(
                                  (leader['timeframes']
                                          as List<dynamic>)
                                      .join('/'),
                                  style: AppTheme.sans(
                                    size: 11,
                                    color: EdgeColors.muted,
                                  ),
                                ),
                              Text(
                                '${leader['followers_count'] ?? 0} followers',
                                style: AppTheme.sans(
                                  size: 11,
                                  color: EdgeColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      EdgeButton(
                        label: 'Unfollow',
                        kind: EdgeButtonKind.ghost,
                        busy: _busyId == -1,
                        onPressed: _unfollow,
                      )
                    else
                      EdgeButton(
                        label: 'Sync',
                        icon: Icons.link,
                        busy: _busyId == leader['id'],
                        onPressed:
                            blocked ? null : () => _follow(leader),
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
