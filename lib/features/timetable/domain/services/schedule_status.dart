import '../entities/train_schedule.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_id.dart';

enum ScheduleStatusKind { upcoming, soon, now, passed, unavailable }

class ScheduleStatus {
  const ScheduleStatus({
    required this.label,
    required this.kind,
    required this.departureAt,
  });

  final String label;
  final ScheduleStatusKind kind;
  final DateTime? departureAt;

  bool get hasDeparted => kind == ScheduleStatusKind.passed;
}

abstract final class ScheduleStatusCalculator {
  static List<TrainSchedule> orderByRelevance({
    required Iterable<TrainSchedule> schedules,
    required DateTime now,
  }) {
    final ranked = schedules.indexed.map((entry) {
      final status = calculate(schedule: entry.$2, now: now);
      return (
        index: entry.$1,
        schedule: entry.$2,
        status: status,
        rank: _orderRank(status.kind),
      );
    }).toList();

    ranked.sort((left, right) {
      if (left.rank != right.rank) return left.rank.compareTo(right.rank);

      final leftDeparture = left.status.departureAt;
      final rightDeparture = right.status.departureAt;
      if (leftDeparture != null && rightDeparture != null) {
        final timestampOrder = left.rank == 1
            ? rightDeparture.compareTo(leftDeparture)
            : leftDeparture.compareTo(rightDeparture);
        if (timestampOrder != 0) return timestampOrder;
      }
      return left.index.compareTo(right.index);
    });

    return ranked.map((entry) => entry.schedule).toList(growable: false);
  }

  static ScheduleStatus calculate({
    required TrainSchedule schedule,
    required DateTime now,
    DateTime? serviceDate,
    AppLocalizations? l10n,
  }) {
    final copy = l10n ?? AppLocalizationsId();
    final parts = schedule.departureTime.split(':');
    if (parts.length != 2) return _unavailable(copy);

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return _unavailable(copy);
    }

    final base = serviceDate ?? now;
    final departureAt = DateTime(
      base.year,
      base.month,
      base.day + schedule.dayOffset,
      hour,
      minute,
    );
    final secondsUntil = departureAt.difference(now).inSeconds;

    if (secondsUntil > 300) {
      final minutes = (secondsUntil / 60).ceil();
      return ScheduleStatus(
        label: copy.scheduleStatusUpcoming(minutes),
        kind: ScheduleStatusKind.upcoming,
        departureAt: departureAt,
      );
    }
    if (secondsUntil > 60) {
      return ScheduleStatus(
        label: copy.scheduleStatusSoon,
        kind: ScheduleStatusKind.soon,
        departureAt: departureAt,
      );
    }
    if (secondsUntil >= -60) {
      return ScheduleStatus(
        label: copy.scheduleStatusNow,
        kind: ScheduleStatusKind.now,
        departureAt: departureAt,
      );
    }
    return ScheduleStatus(
      label: copy.scheduleStatusPassed,
      kind: ScheduleStatusKind.passed,
      departureAt: departureAt,
    );
  }

  static ScheduleStatus _unavailable(AppLocalizations l10n) => ScheduleStatus(
    label: l10n.scheduleStatusUnavailable,
    kind: ScheduleStatusKind.unavailable,
    departureAt: null,
  );

  static int _orderRank(ScheduleStatusKind kind) => switch (kind) {
    ScheduleStatusKind.upcoming ||
    ScheduleStatusKind.soon ||
    ScheduleStatusKind.now => 0,
    ScheduleStatusKind.passed => 1,
    ScheduleStatusKind.unavailable => 2,
  };
}
