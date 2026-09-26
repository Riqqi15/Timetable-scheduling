import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable/features/timetable/domain/entities/train_schedule.dart';
import 'package:timetable/features/timetable/presentation/widgets/schedule_card.dart';

import 'helpers/localized_test_app.dart';

void main() {
  testWidgets('schedule time blocks use commuter and direction icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: const Scaffold(
          body: ScheduleCard(
            schedule: TrainSchedule(
              trainName: 'KA 1234',
              route: 'Duri - Tangerang',
              departureTime: '22:24',
              arrivalTime: '22:50',
              platform: '2',
              trainType: 'KRL',
              stationName: 'Duri',
              isWeekend: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.train_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
    expect(find.byIcon(Icons.south_west_rounded), findsOneWidget);
  });
}
