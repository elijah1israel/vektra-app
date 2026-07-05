import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';

class WalletMenu extends StatelessWidget {
  const WalletMenu({super.key});

  String _fmtCents(int cents) {
    final sign = cents < 0 ? '-' : '';
    return '$sign\$${(cents.abs() / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final balance = auth.user?.usdtCreditCents ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.push('/pricing'),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: EdgeColors.border),
          color: EdgeColors.surface.withOpacity(0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 14, color: EdgeColors.accent),
            const SizedBox(width: 6),
            Text(
              _fmtCents(balance),
              style: AppTheme.sans(
                size: 12.5,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
