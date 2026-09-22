import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../timetable/domain/entities/train_schedule.dart';
import '../../../timetable/presentation/controllers/timetable_controller.dart';

enum NextTrainState { idle, loading, success, empty, error }

class NextTrainDeparture {
  const NextTrainDeparture({
    required this.schedule,
    required this.departureAt,
    required this.minutesUntilDeparture,
  });

  final TrainSchedule schedule;
  final DateTime departureAt;
  final int minutesUntilDeparture;
}

class NextTrainDirectionGroup {
  const NextTrainDirectionGroup({
    required this.nextStation,
    required this.departures,
  });

  final String nextStation;
  final List<NextTrainDeparture> departures;
}

class NextTrainController extends ChangeNotifier {
  NextTrainController({
    TimetableController? timetable,
    DateTime Function()? now,
    bool startTimer = true,
  }) : _timetable = timetable ?? TimetableController(),
       _now = now ?? DateTime.now {
    if (startTimer) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    }
  }

  final TimetableController _timetable;
  final DateTime Function() _now;
  Timer? _timer;
  int _generation = 0;
  List<TrainSchedule> _schedules = const [];
  DateTime? _loadedDate;

  NextTrainState state = NextTrainState.idle;
  String? stationName;
  List<NextTrainDirectionGroup> groups = const [];
  bool isRefreshing = false;
  bool hasRefreshError = false;

  Future<void> loadStation(String? station, {bool force = false}) async {
    final normalized = station?.trim();
    if (normalized == null || normalized.isEmpty) {
      ++_generation;
      stationName = null;
      _schedules = const [];
      groups = const [];
      state = NextTrainState.idle;
      isRefreshing = false;
      hasRefreshError = false;
      notifyListeners();
      return;
    }
    if (!force && normalized == stationName && state != NextTrainState.error) {
      return;
    }

    final generation = ++_generation;
    final stationChanged = normalized != stationName;
    stationName = normalized;
    if (stationChanged) {
      _schedules = const [];
      groups = const [];
    }
    hasRefreshError = false;
    isRefreshing = groups.isNotEmpty;
    if (!isRefreshing) state = NextTrainState.loading;
    notifyListeners();

    final current = _now();
    try {
      final schedules = await _timetable.loadSchedules(
        station: normalized,
        trainType: 'KRL',
        isWeekend: current.weekday >= DateTime.saturday,
      );
      if (generation != _generation) return;
      _schedules = schedules;
      _loadedDate = DateTime(current.year, current.month, current.day);
      isRefreshing = false;
      _rebuild(current);
    } on Object {
      if (generation != _generation) return;
      isRefreshing = false;
      if (groups.isNotEmpty) {
        hasRefreshError = true;
        state = NextTrainState.success;
      } else {
        state = NextTrainState.error;
      }
      notifyListeners();
    }
  }

  Future<void> retry() => loadStation(stationName, force: true);

  void _tick() {
    final current = _now();
    final loadedDate = _loadedDate;
    if (stationName != null &&
        loadedDate != null &&
        (loadedDate.year != current.year ||
            loadedDate.month != current.month ||
            loadedDate.day != current.day)) {
      unawaited(loadStation(stationName, force: true));
      return;
    }
    if (_schedules.isNotEmpty) _rebuild(current);
  }

  void _rebuild(DateTime current) {
    final grouped = <String, List<NextTrainDeparture>>{};
    for (final schedule in _schedules) {
      final nextStation = schedule.nextStation?.trim() ?? '';
      final destination = schedule.destination?.trim() ?? '';
      final parts = schedule.departureTime.split(':');
      if (nextStation.isEmpty || destination.isEmpty || parts.length != 2) {
        continue;
      }
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;
      final departureAt = DateTime(
        current.year,
        current.month,
        current.day,
        hour,
        minute,
      ).add(Duration(days: schedule.dayOffset));
      if (departureAt.isBefore(current)) continue;
      final minutes = (departureAt.difference(current).inSeconds / 60).ceil();
      grouped
          .putIfAbsent(nextStation, () => [])
          .add(
            NextTrainDeparture(
              schedule: schedule,
              departureAt: departureAt,
              minutesUntilDeparture: minutes,
            ),
          );
    }

    final nextGroups =
        grouped.entries.map((entry) {
          entry.value.sort((a, b) => a.departureAt.compareTo(b.departureAt));
          return NextTrainDirectionGroup(
            nextStation: entry.key,
            departures: entry.value.take(2).toList(growable: false),
          );
        }).toList()..sort(
          (a, b) => a.departures.first.departureAt.compareTo(
            b.departures.first.departureAt,
          ),
        );
    groups = nextGroups;
    state = groups.isEmpty ? NextTrainState.empty : NextTrainState.success;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
