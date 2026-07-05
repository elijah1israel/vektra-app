import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/instrument.dart';

/// Call once at app boot.
void initTimezones() => tzdata.initializeTimeZones();

/// FX weekend block — Fri 22:00 UTC → Sun 22:00 UTC. Mirrors
/// engine._market_closed on the web app.
bool _inMarketClosedWindow(DateTime utc) {
  final dow = (utc.weekday + 6) % 7; // 0=Mon … 6=Sun
  final h = utc.hour;
  return dow == 5 ||
      (dow == 6 && h < 22) ||
      (dow == 4 && h >= 22);
}

/// Next firing of a single schedule after [fromUtc]. The schedule's hour /
/// minute / days[] are read in `schedule.tz` (falls back to UTC), so we
/// walk forward 14 wall-clock days in that zone and pick the earliest
/// instant that also passes the weekend block if [weekendBlock] is set.
///
/// Uses the IANA tz database, so DST flips in the session zone shift
/// firings correctly against candle closes.
DateTime? nextFiringForSchedule(
  Schedule schedule, {
  required bool weekendBlock,
  required DateTime fromUtc,
}) {
  final tzName = schedule.tz ?? 'UTC';
  final tz.Location loc;
  try {
    loc = tz.getLocation(tzName);
  } catch (_) {
    return null;
  }
  final fromInSession = tz.TZDateTime.from(fromUtc, loc);
  for (var i = 0; i < 14; i++) {
    final candidate = tz.TZDateTime(
      loc,
      fromInSession.year,
      fromInSession.month,
      fromInSession.day + i,
      schedule.hour,
      schedule.minute,
    );
    if (!candidate.isAfter(fromInSession)) continue;
    if (schedule.days.isNotEmpty) {
      // schedule.days uses 0=Mon … 6=Sun, matching the web app.
      final dowInSession = (candidate.weekday + 6) % 7;
      if (!schedule.days.contains(dowInSession)) continue;
    }
    final asUtc = candidate.toUtc();
    if (weekendBlock && _inMarketClosedWindow(asUtc)) continue;
    return asUtc;
  }
  return null;
}

class NextRun {
  const NextRun({required this.at, required this.subscription});
  final DateTime at; // UTC instant
  final Subscription subscription;
}

/// Earliest firing across every active schedule on every active
/// subscription, or null if nothing is scheduled.
NextRun? computeNextRun(
  List<Subscription> subs, {
  DateTime? fromUtc,
}) {
  final now = (fromUtc ?? DateTime.now().toUtc()).toUtc();
  DateTime? earliest;
  Subscription? owner;
  for (final sub in subs) {
    if (!sub.isActive) continue;
    for (final sc in sub.schedules) {
      if (!sc.isActive) continue;
      final t = nextFiringForSchedule(
        sc,
        weekendBlock: sub.weekendBlock,
        fromUtc: now,
      );
      if (t != null && (earliest == null || t.isBefore(earliest))) {
        earliest = t;
        owner = sub;
      }
    }
  }
  if (earliest == null || owner == null) return null;
  return NextRun(at: earliest, subscription: owner);
}
