int _asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class Instrument {
  Instrument({
    required this.id,
    required this.label,
    required this.symbol,
    this.sessionTz,
    this.hasCompanion = false,
    this.companionLabel,
  });

  factory Instrument.fromJson(Map<String, dynamic> j) => Instrument(
        id: _asInt(j['id']),
        label: (j['label'] ?? '') as String,
        symbol: (j['symbol'] ?? '') as String,
        sessionTz: j['session_tz'] as String?,
        hasCompanion: j['has_companion'] == true,
        companionLabel: j['companion_label'] as String?,
      );

  final int id;
  final String label;
  final String symbol;
  final String? sessionTz;
  final bool hasCompanion;
  final String? companionLabel;
}

class Schedule {
  Schedule({
    required this.hour,
    required this.minute,
    required this.days,
    this.tz,
    this.isActive = true,
  });

  factory Schedule.fromJson(Map<String, dynamic> j) => Schedule(
        hour: _asInt(j['hour']),
        minute: _asInt(j['minute']),
        days: (j['days'] as List<dynamic>?)
                ?.map((e) => _asInt(e))
                .toList() ??
            const [],
        tz: j['tz'] as String?,
        isActive: j['is_active'] != false,
      );

  final int hour;
  final int minute;
  final List<int> days;
  final String? tz;
  final bool isActive;
}

class Subscription {
  Subscription({
    required this.id,
    required this.instrument,
    this.schedules = const [],
    this.timeframes = const [],
    this.minRr,
    this.tpMode,
    this.orderType,
    this.strategy,
    this.isActive = true,
    this.weekendBlock = false,
  });

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: _asInt(j['id']),
        instrument: Instrument.fromJson(
            (j['instrument'] as Map).cast<String, dynamic>()),
        schedules: (j['schedules'] as List<dynamic>? ?? const [])
            .map((e) => Schedule.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        timeframes: (j['timeframes'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        // DRF's DecimalField serialises as a String by default — parse
        // both cases so a subscribed instrument is actually recognised.
        minRr: _asDouble(j['min_rr']),
        tpMode: j['tp_mode'] as String?,
        orderType: j['order_type'] as String?,
        strategy: j['strategy'] as String?,
        isActive: j['is_active'] != false,
        weekendBlock: j['weekend_block'] == true,
      );

  final int id;
  final Instrument instrument;
  final List<Schedule> schedules;
  final List<String> timeframes;
  final double? minRr;
  final String? tpMode;
  final String? orderType;
  final String? strategy;
  final bool isActive;
  final bool weekendBlock;
}
