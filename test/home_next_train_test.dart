import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timetable/features/home/data/krl_station_locations.dart';
import 'package:timetable/features/home/data/services/user_location_service.dart';
import 'package:timetable/features/home/presentation/controllers/next_train_controller.dart';
import 'package:timetable/features/home/presentation/pages/home_page.dart';
import 'package:timetable/features/timetable/domain/entities/train_schedule.dart';
import 'package:timetable/features/timetable/presentation/controllers/timetable_controller.dart';
import 'package:timetable/l10n/app_localizations.dart';

import 'helpers/fake_tracking_location.dart';

class _Timetable implements TimetableController {
  @override
  Future<List<TrainSchedule>> loadSchedules({
    String? station,
    String? trainType,
    bool? isWeekend,
  }) async => const [
    TrainSchedule(
      trainName: 'KA 101',
      route: 'Bogor - Jakarta Kota',
      departureTime: '18:05',
      arrivalTime: '18:30',
      platform: '',
      trainType: 'KRL',
      stationName: 'Manggarai',
      isWeekend: false,
      nextStation: 'Cikini',
      destination: 'Jakarta Kota',
      direction: 'NORTHBOUND',
    ),
    TrainSchedule(
      trainName: 'KA 202',
      route: 'Jakarta Kota - Bogor',
      departureTime: '18:08',
      arrivalTime: '19:00',
      platform: '12',
      trainType: 'KRL',
      stationName: 'Manggarai',
      isWeekend: false,
      nextStation: 'Tebet',
      destination: 'Bogor',
      direction: 'SOUTHBOUND',
    ),
  ];
}

void main() {
  testWidgets(
    'home shows real departures for every nearest-station direction',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final gateway = FakeTrackingLocation();
      addTearDown(gateway.dispose);
      final nextTrain = NextTrainController(
        timetable: _Timetable(),
        now: () => DateTime(2026, 9, 23, 18),
        startTimer: false,
      );
      addTearDown(nextTrain.dispose);
      final router = GoRouter(
        initialLocation: '/?selected=Manggarai',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => HomePage(
              nextTrainController: nextTrain,
              locationService: UserLocationService(gateway: gateway),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      final manggarai = krlStationLocations.firstWhere(
        (station) => station.name == 'Manggarai',
      );
      gateway.positions.add(
        UserCoordinates(
          latitude: manggarai.latitude,
          longitude: manggarai.longitude,
          accuracyMeters: 5,
          timestamp: DateTime.now(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kereta berikutnya dari Manggarai'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('next-train-direction-Cikini')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('next-train-direction-Tebet')),
        findsOneWidget,
      );
      expect(find.text('KA 101 · 18:05'), findsOneWidget);
      expect(find.text('KA 202 · 18:08'), findsOneWidget);
      expect(find.text('Peron belum tersedia'), findsOneWidget);
      expect(find.text('Berangkat 5 menit lagi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
