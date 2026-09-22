import 'package:flutter_test/flutter_test.dart';
import 'package:timetable/features/home/presentation/controllers/next_train_controller.dart';
import 'package:timetable/features/timetable/domain/entities/train_schedule.dart';
import 'package:timetable/features/timetable/presentation/controllers/timetable_controller.dart';

TrainSchedule _schedule({
  required String train,
  required String time,
  required String next,
  required String destination,
  int dayOffset = 0,
}) => TrainSchedule(
  trainName: train,
  route: 'Manggarai - $destination',
  departureTime: time,
  arrivalTime: time,
  platform: '',
  trainType: 'KRL',
  stationName: 'Manggarai',
  isWeekend: false,
  dayOffset: dayOffset,
  nextStation: next.isEmpty ? null : next,
  destination: destination,
  direction: next,
);

class _Timetable implements TimetableController {
  _Timetable(this.handler);

  final Future<List<TrainSchedule>> Function() handler;
  String? station;
  String? trainType;
  bool? isWeekend;

  @override
  Future<List<TrainSchedule>> loadSchedules({
    String? station,
    String? trainType,
    bool? isWeekend,
  }) {
    this.station = station;
    this.trainType = trainType;
    this.isWeekend = isWeekend;
    return handler();
  }
}

void main() {
  test('groups every future direction and limits each group to two', () async {
    final timetable = _Timetable(
      () async => [
        _schedule(
          train: 'KA past',
          time: '17:55',
          next: 'Cikini',
          destination: 'Jakarta Kota',
        ),
        _schedule(
          train: 'KA 1',
          time: '18:05',
          next: 'Cikini',
          destination: 'Jakarta Kota',
        ),
        _schedule(
          train: 'KA 2',
          time: '18:08',
          next: 'Cikini',
          destination: 'Jakarta Kota',
        ),
        _schedule(
          train: 'KA 3',
          time: '18:12',
          next: 'Cikini',
          destination: 'Jakarta Kota',
        ),
        _schedule(
          train: 'KA 4',
          time: '18:10',
          next: 'Tebet',
          destination: 'Bogor',
        ),
        _schedule(
          train: 'KA terminal',
          time: '18:01',
          next: '',
          destination: 'Manggarai',
        ),
      ],
    );
    final controller = NextTrainController(
      timetable: timetable,
      now: () => DateTime(2026, 9, 21, 18),
      startTimer: false,
    );
    addTearDown(controller.dispose);

    await controller.loadStation('Manggarai');

    expect(timetable.station, 'Manggarai');
    expect(timetable.trainType, 'KRL');
    expect(timetable.isWeekend, isFalse);
    expect(controller.state, NextTrainState.success);
    expect(controller.groups.map((group) => group.nextStation), [
      'Cikini',
      'Tebet',
    ]);
    expect(controller.groups.first.departures, hasLength(2));
    expect(controller.groups.first.departures.first.minutesUntilDeparture, 5);
  });

  test('supports a departure after midnight through dayOffset', () async {
    final timetable = _Timetable(
      () async => [
        _schedule(
          train: 'KA malam',
          time: '00:03',
          next: 'Cikini',
          destination: 'Jakarta Kota',
          dayOffset: 1,
        ),
      ],
    );
    final controller = NextTrainController(
      timetable: timetable,
      now: () => DateTime(2026, 9, 21, 23, 58),
      startTimer: false,
    );
    addTearDown(controller.dispose);

    await controller.loadStation('Manggarai');

    expect(controller.groups.single.departures.single.minutesUntilDeparture, 5);
  });

  test('keeps cached departures when a refresh fails', () async {
    var shouldFail = false;
    final timetable = _Timetable(() async {
      if (shouldFail) throw Exception('offline');
      return [
        _schedule(
          train: 'KA 1',
          time: '18:05',
          next: 'Cikini',
          destination: 'Jakarta Kota',
        ),
      ];
    });
    final controller = NextTrainController(
      timetable: timetable,
      now: () => DateTime(2026, 9, 21, 18),
      startTimer: false,
    );
    addTearDown(controller.dispose);

    await controller.loadStation('Manggarai');
    shouldFail = true;
    await controller.loadStation('Manggarai', force: true);

    expect(controller.state, NextTrainState.success);
    expect(controller.hasRefreshError, isTrue);
    expect(controller.groups, isNotEmpty);
  });
}
