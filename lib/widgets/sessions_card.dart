import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'edge_card.dart';

class _Session {
  const _Session(this.name, this.hue, this.open, this.close);
  final String name;
  final int hue;
  final int open;
  final int close;
}

const _sessions = [
  _Session('Sydney', 38, 8, 17),
  _Session('Tokyo', 0, 9, 18),
  _Session('London', 220, 8, 17),
  _Session('New York', 142, 8, 17),
];

class SessionsCard extends StatefulWidget {
  const SessionsCard({super.key});
  @override
  State<SessionsCard> createState() => _SessionsCardState();
}

class _SessionsCardState extends State<SessionsCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EdgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: EdgeColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: EdgeColors.accent.withOpacity(0.2)),
                ),
                child: const Icon(Icons.public,
                    color: EdgeColors.accent, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market sessions',
                      style: AppTheme.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'The four major forex sessions — weekdays only.',
                      style: AppTheme.sans(
                          size: 11.5,
                          color: EdgeColors.muted,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (ctx, box) {
            final wide = box.maxWidth > 420;
            final tiles = _sessions.map((s) => _Tile(session: s, now: _now));
            if (!wide) {
              return Column(
                children: [
                  for (final t in tiles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: t,
                    ),
                ],
              );
            }
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3.0,
              children: tiles.toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.session, required this.now});
  final _Session session;
  final DateTime now;

  Color get _color => HSLColor.fromAHSL(1, session.hue.toDouble(), 0.7, 0.6)
      .toColor();

  bool get _isOpen {
    final wd = now.weekday; // 1..7 (Mon=1)
    final h = now.hour;
    return wd >= 1 && wd <= 5 && h >= session.open && h < session.close;
  }

  String get _clock =>
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return SolidCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      background: EdgeColors.card.withOpacity(0.6),
      borderColor: EdgeColors.white08,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isOpen ? _color : EdgeColors.muted,
              boxShadow: _isOpen
                  ? [BoxShadow(color: _color, blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name.toUpperCase(),
                  style: AppTheme.sans(
                    size: 10.5,
                    weight: FontWeight.w600,
                    color: EdgeColors.muted,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _clock,
                  style: AppTheme.mono(
                    size: 20,
                    color: _isOpen ? _color : Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _isOpen ? 'Open' : 'Closed',
            style: AppTheme.sans(size: 11, color: EdgeColors.muted),
          ),
        ],
      ),
    );
  }
}
