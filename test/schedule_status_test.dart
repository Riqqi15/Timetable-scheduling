import 'package:flutter_test/flutter_test.dart';
import 'package:timetable/features/timetable/domain/entities/train_schedule.dart';
import 'package:timetable/features/timetable/domain/services/schedule_status.dart';

TrainSchedule schedule(String name, String departureTime, {int dayOffset = 0}) {
  return TrainSchedule(
    trainName: name,
    route: 'Origin - Destination',
    departureTime: departureTime,
    arrivalTime: departureTime,
    platform: '1',
    trainType: 'KRL',
    stationName: 'Origin',
    isWeekend: false,
    dayOffset: dayOffset,
  );
}

void main() {
  const baseSchedule = TrainSchedule(
    trainName: 'KRL 1001',
    route: 'Bogor - Jakarta Kota',
    departureTime: '10:00',
    arrivalTime: '11:00',
    platform: '1',
    trainType: 'KRL',
    stationName: 'Bogor',
    isWeekend: false,
  );

  group('ScheduleStatusCalculator', () {
    test('shows a countdown when departure is more than five minutes away', () {
      final status = ScheduleStatusCalculator.calculate(
        schedule: baseSchedule,
        now: DateTime(2026, 8, 15, 9, 53),
      );

      expect(status.label, 'Berangkat 7 menit lagi');
      expect(status.kind, ScheduleStatusKind.upcoming);
      expect(status.hasDeparted, isFalse);
    });

    test('shows soon inside the five-minute window', () {
      final status = ScheduleStatusCalculator.calculate(
        schedule: baseSchedule,
        now: DateTime(2026, 8, 15, 9, 57),
      );

      expect(status.label, 'Segera berangkat');
      expect(status.kind, ScheduleStatusKind.soon);
    });

    test('shows now inside the one-minute tolerance', () {
      for (final now in [
        DateTime(2026, 8, 15, 9, 59),
        DateTime(2026, 8, 15, 10),
        DateTime(2026, 8, 15, 10, 1),
      ]) {
        final status = ScheduleStatusCalculator.calculate(
          schedule: baseSchedule,
          now: now,
        );
        expect(status.label, 'Berangkat sekarang');
        expect(status.kind, ScheduleStatusKind.now);
      }
    });

    test('marks a schedule as passed after the tolerance', () {
      final status = ScheduleStatusCalculator.calculate(
        schedule: baseSchedule,
        now: DateTime(2026, 8, 15, 10, 2),
      );

      expect(status.label, 'Jadwal lewat');
      expect(status.kind, ScheduleStatusKind.passed);
      expect(status.hasDeparted, isTrue);
    });

    test('honors dayOffset for after-midnight service calls', () {
      const nextDay = TrainSchedule(
        trainName: 'KRL 1002',
        route: 'Jakarta Kota - Bogor',
        departureTime: '00:05',
        arrivalTime: '01:15',
        platform: '2',
        trainType: 'KRL',
        stationName: 'Jakarta Kota',
        isWeekend: false,
        dayOffset: 1,
      );

      final status = ScheduleStatusCalculator.calculate(
        schedule: nextDay,
        now: DateTime(2026, 8, 15, 23, 59),
      );

      expect(status.label, 'Berangkat 6 menit lagi');
      expect(status.departureAt, DateTime(2026, 8, 16, 0, 5));
    });

    test('handles malformed departure time without crashing', () {
      const invalid = TrainSchedule(
        trainName: 'KRL 1003',
        route: 'Bogor - Jakarta Kota',
        departureTime: '--',
        arrivalTime: '--',
        platform: '-',
        trainType: 'KRL',
        stationName: 'Bogor',
        isWeekend: false,
      );

      final status = ScheduleStatusCalculator.calculate(
        schedule: invalid,
        now: DateTime(2026, 8, 15, 10),
      );

      expect(status.kind, ScheduleStatusKind.unavailable);
      expect(status.label, 'Status jadwal tidak tersedia');
    });

    test('orders upcoming nearest first and passed schedules newest first', () {
      final source = [
        schedule('Early', '04:00'),
        schedule('Later', '18:30'),
        schedule('Recently passed', '17:55'),
        schedule('Nearest', '18:05'),
        schedule('Unavailable', '--'),
      ];

      final ordered = ScheduleStatusCalculator.orderByRelevance(
        schedules: source,
        now: DateTime(2026, 9, 22, 18),
      );

      expect(ordered.map((item) => item.departureTime), [
        '18:05',
        '18:30',
        '17:55',
        '04:00',
        '--',
      ]);
      expect(source.map((item) => item.departureTime), [
        '04:00',
        '18:30',
        '17:55',
        '18:05',
        '--',
      ]);
    });

    test('orders after-midnight dayOffset as an upcoming departure', () {
      final ordered = ScheduleStatusCalculator.orderByRelevance(
        schedules: [
          schedule('Passed', '23:00'),
          schedule('After midnight', '00:05', dayOffset: 1),
        ],
        now: DateTime(2026, 9, 22, 23, 59),
      );

      expect(ordered.map((item) => item.trainName), [
        'After midnight',
        'Passed',
      ]);
    });

    test('keeps equal departure timestamps stable', () {
      final ordered = ScheduleStatusCalculator.orderByRelevance(
        schedules: [schedule('First', '18:05'), schedule('Second', '18:05')],
        now: DateTime(2026, 9, 22, 18),
      );

      expect(ordered.map((item) => item.trainName), ['First', 'Second']);
    });
  });
}
