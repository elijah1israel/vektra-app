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
import '../../widgets/page_header.dart';
import '../../widgets/spinner.dart';
import '../../widgets/toast.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});
  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  List<Map<String, dynamic>> _tiers = [];
  bool _loading = true;
  String? _busyKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/billing/tiers/');
      final list = (res.data as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      setState(() {
        _tiers = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ToastMessenger.instance.error(describeError(e));
    }
  }

  Future<void> _subscribe(Map<String, dynamic> tier) async {
    setState(() => _busyKey = tier['key'] as String);
    try {
      final api = context.read<ApiClient>();
      await api.dio
          .post('/billing/subscribe/', data: {'tier': tier['key']});
      await context.read<AuthState>().refreshProfile();
      ToastMessenger.instance
          .success("You're on ${tier['label']}. Enjoy 30 days.");
      if (mounted) context.go('/dashboard');
    } catch (e) {
      ToastMessenger.instance.error(describeError(e));
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  String _formatPrice(int cents) =>
      cents == 0 ? 'Free' : '\$${(cents / 100).round()}';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const PageSpinner();
    final user = context.watch<AuthState>().user;
    final balance = user?.usdtCreditCents ?? 0;
    final currentKey = user?.tier?.key;
    final paid = _tiers
        .where((t) => (t['price_cents'] as num? ?? 0) > 0)
        .toList()
      ..sort((a, b) => (a['sort_order'] as int? ?? 0)
          .compareTo(b['sort_order'] as int? ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: 'Plans',
          title: const Text('Pricing'),
          subtitle:
              'Pay in USDT — no KYC. Top up your wallet, pick a plan, the credit lasts 30 days from purchase.',
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: EdgeColors.accent.withOpacity(0.05),
              border: Border.all(
                color: EdgeColors.accent.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 14, color: EdgeColors.accent),
                const SizedBox(width: 8),
                Text(
                  '\$${(balance / 100).toStringAsFixed(2)}',
                  style: AppTheme.sans(
                    size: 13,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text('balance',
                    style: AppTheme.sans(
                        size: 11, color: EdgeColors.muted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...paid.map((tier) {
          final isCurrent = currentKey == tier['key'];
          final highlight = tier['key'] == 'pro';
          final priceCents = (tier['price_cents'] as num?)?.toInt() ?? 0;
          final canAfford = balance >= priceCents;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EdgeCard(
              borderColor: highlight
                  ? EdgeColors.accent.withOpacity(0.4)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (highlight)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: EdgeColors.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'MOST POPULAR',
                        style: AppTheme.sans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: EdgeColors.bg,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  Text(
                    (tier['label'] as String? ?? '').toUpperCase(),
                    style: AppTheme.sans(
                      size: 11,
                      weight: FontWeight.w600,
                      color: EdgeColors.muted,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatPrice(priceCents),
                        style: AppTheme.display(
                          size: 30,
                          weight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('/ month',
                          style: AppTheme.sans(
                              size: 12, color: EdgeColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._perkRow(
                      'Analyses per day', tier['analyses_per_day']),
                  ..._perkRow('Instrument subscriptions',
                      tier['max_subscriptions']),
                  ..._perkRow(
                      'Trader follows', tier['max_follows']),
                  const SizedBox(height: 14),
                  EdgeButton(
                    label: isCurrent ? 'Renew · 30 days' : 'Subscribe',
                    trailing: Icons.arrow_forward,
                    fullWidth: true,
                    busy: _busyKey == tier['key'],
                    kind: highlight
                        ? EdgeButtonKind.primary
                        : EdgeButtonKind.ghost,
                    onPressed: canAfford ? () => _subscribe(tier) : null,
                  ),
                  if (!canAfford) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text('Top up your wallet first.',
                          style: AppTheme.sans(
                            size: 11.5,
                            color: EdgeColors.muted,
                          )),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  List<Widget> _perkRow(String label, dynamic value) {
    final v = (value as num?)?.toInt();
    final unlimited = v == null || v < 0;
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              unlimited ? Icons.all_inclusive : Icons.check,
              size: 15,
              color: EdgeColors.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTheme.sans(
                      size: 12.5, color: EdgeColors.slate300),
                  children: [
                    TextSpan(
                      text: unlimited ? 'Unlimited' : '$v',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: ' ${label.toLowerCase()}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
