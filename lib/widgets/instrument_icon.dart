import 'package:flutter/material.dart';

class _Asset {
  const _Asset(this.icon, this.color);
  final IconData icon;
  final Color color;
}

const _currencyMap = <String, _Asset>{
  'BTC': _Asset(Icons.currency_bitcoin, Color(0xFFF7931A)),
  'XAU': _Asset(Icons.monetization_on_outlined, Color(0xFFFCD34D)),
  'XAG': _Asset(Icons.monetization_on_outlined, Color(0xFFCBD5E1)),
  'EUR': _Asset(Icons.euro, Color(0xFF60A5FA)),
  'GBP': _Asset(Icons.currency_pound, Color(0xFF818CF8)),
  'JPY': _Asset(Icons.currency_yen, Color(0xFFF472B6)),
  'CHF': _Asset(Icons.currency_franc, Color(0xFFF87171)),
  'AUD': _Asset(Icons.attach_money, Color(0xFFFBBF24)),
  'CAD': _Asset(Icons.attach_money, Color(0xFFFB923C)),
  'NZD': _Asset(Icons.attach_money, Color(0xFF2DD4BF)),
  'USD': _Asset(Icons.attach_money, Color(0xFF34D399)),
};

String _assetOf(String label, String symbol) {
  final raw = (label.isNotEmpty ? label : symbol)
      .replaceAll(RegExp(r'^[A-Za-z]+:'), '')
      .toUpperCase();
  if (raw.length < 3) return raw;
  final base = raw.substring(0, 3);
  final quote = raw.length >= 6 ? raw.substring(3, 6) : '';
  if (base == 'USD' && _currencyMap.containsKey(quote)) return quote;
  return base;
}

class InstrumentIconBadge extends StatelessWidget {
  const InstrumentIconBadge({
    super.key,
    required this.label,
    required this.symbol,
    this.size = 44,
  });

  final String label;
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = _currencyMap[_assetOf(label, symbol)] ??
        const _Asset(Icons.candlestick_chart_outlined, Color(0xFF94A3B8));
    final color = asset.color;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: color.withOpacity(0.24)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.07),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Icon(asset.icon, color: color, size: size * 0.5),
    );
  }
}
