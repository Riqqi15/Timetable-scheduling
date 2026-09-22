# Nearest Schedule Ordering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the nearest valid departure first using the phone's local time, keep passed departures at the bottom, and preserve correct after-midnight ordering.

**Architecture:** Add a pure, stable ordering operation beside `ScheduleStatusCalculator`, then call it from `TimetablePage` after the existing filters. The page continues refreshing `_now` every 30 seconds, so the ordering updates without another API request.

**Tech Stack:** Flutter, Dart, `flutter_test`

---

## File Map

- Modify `lib/features/timetable/domain/services/schedule_status.dart`: calculate relevance groups and stable timestamp ordering.
- Modify `lib/features/timetable/presentation/pages/timetable_page.dart`: inject a test clock and use the domain ordering after filtering.
- Modify `test/schedule_status_test.dart`: verify active, passed, unavailable, stable, and cross-midnight cases.
- Modify `test/timetable_page_catalog_test.dart`: verify the first rendered card follows the supplied phone time.

### Task 1: Domain ordering

**Files:**
- Modify: `lib/features/timetable/domain/services/schedule_status.dart`
- Test: `test/schedule_status_test.dart`

- [ ] **Step 1: Write failing domain tests**

Add this helper above `main()`:

```dart
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
```

Add these tests inside the existing `ScheduleStatusCalculator` group:

```dart
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

  expect(
    ordered.map((item) => item.departureTime),
    ['18:05', '18:30', '17:55', '04:00', '--'],
  );
  expect(
    source.map((item) => item.departureTime),
    ['04:00', '18:30', '17:55', '18:05', '--'],
  );
});

test('orders after-midnight dayOffset as an upcoming departure', () {
  final ordered = ScheduleStatusCalculator.orderByRelevance(
    schedules: [
      schedule('Passed', '23:00'),
      schedule('After midnight', '00:05', dayOffset: 1),
    ],
    now: DateTime(2026, 9, 22, 23, 59),
  );

  expect(ordered.map((item) => item.trainName), ['After midnight', 'Passed']);
});

test('keeps equal departure timestamps stable', () {
  final ordered = ScheduleStatusCalculator.orderByRelevance(
    schedules: [schedule('First', '18:05'), schedule('Second', '18:05')],
    now: DateTime(2026, 9, 22, 18),
  );

  expect(ordered.map((item) => item.trainName), ['First', 'Second']);
});
```

- [ ] **Step 2: Run the domain test and confirm failure**

Run:

```powershell
flutter test test/schedule_status_test.dart
```

Expected: FAIL because `orderByRelevance` does not exist.

- [ ] **Step 3: Implement the stable ordering operation**

Add this public operation to `ScheduleStatusCalculator`:

```dart
static List<TrainSchedule> orderByRelevance({
  required Iterable<TrainSchedule> schedules,
  required DateTime now,
}) {
  final indexed = schedules.indexed.toList();
  indexed.sort((left, right) {
    final leftStatus = calculate(schedule: left.$2, now: now);
    final rightStatus = calculate(schedule: right.$2, now: now);
    final leftRank = _orderRank(leftStatus.kind);
    final rightRank = _orderRank(rightStatus.kind);
    if (leftRank != rightRank) return leftRank.compareTo(rightRank);

    final leftDeparture = leftStatus.departureAt;
    final rightDeparture = rightStatus.departureAt;
    if (leftDeparture != null && rightDeparture != null) {
      final timestampOrder = leftRank == 1
          ? rightDeparture.compareTo(leftDeparture)
          : leftDeparture.compareTo(rightDeparture);
      if (timestampOrder != 0) return timestampOrder;
    }
    return left.$1.compareTo(right.$1);
  });
  return indexed.map((entry) => entry.$2).toList(growable: false);
}

static int _orderRank(ScheduleStatusKind kind) => switch (kind) {
  ScheduleStatusKind.upcoming ||
  ScheduleStatusKind.soon ||
  ScheduleStatusKind.now => 0,
  ScheduleStatusKind.passed => 1,
  ScheduleStatusKind.unavailable => 2,
};
```

- [ ] **Step 4: Run the domain test**

Run:

```powershell
flutter test test/schedule_status_test.dart
```

Expected: all schedule status and ordering tests pass.

### Task 2: Timetable page integration

**Files:**
- Modify: `lib/features/timetable/presentation/pages/timetable_page.dart`
- Test: `test/timetable_page_catalog_test.dart`

- [ ] **Step 1: Write a failing widget test**

Import `schedule_card.dart`, add a local schedule factory, then extend the fake controller so it can return supplied schedules:

```dart
TrainSchedule _schedule(String name, String departureTime) => TrainSchedule(
  trainName: name,
  route: 'Origin - Destination',
  departureTime: departureTime,
  arrivalTime: departureTime,
  platform: '1',
  trainType: 'KRL',
  stationName: 'Origin',
  isWeekend: false,
);

class _Controller implements TimetableController {
  _Controller([this.schedules = const []]);

  final List<TrainSchedule> schedules;
  final List<String?> requested = [];

  @override
  Future<List<TrainSchedule>> loadSchedules({
    String? station,
    String? trainType,
    bool? isWeekend,
  }) async {
    requested.add(station);
    return schedules;
  }
}
```

Add this widget test:

```dart
testWidgets('shows the nearest upcoming schedule first for phone time', (
  tester,
) async {
  final controller = _Controller([
    _schedule('Early', '04:00'),
    _schedule('Later', '18:30'),
    _schedule('Nearest', '18:05'),
  ]);
  final source = StationRemoteDataSource(
    client: MockClient((_) async => http.Response('{"data":[]}', 200)),
  );

  await tester.pumpWidget(
    localizedTestApp(
      locale: const Locale('id'),
      home: TimetablePage(
        controller: controller,
        stationDataSource: source,
        now: () => DateTime(2026, 9, 22, 18),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final firstCard = tester.widget<ScheduleCard>(find.byType(ScheduleCard).first);
  expect(firstCard.schedule.trainName, 'Nearest');
  await tester.pumpWidget(const SizedBox());
});
```

- [ ] **Step 2: Run the widget test and confirm failure**

Run:

```powershell
flutter test test/timetable_page_catalog_test.dart
```

Expected: FAIL because `TimetablePage` has no injectable clock and still performs chronological sorting.

- [ ] **Step 3: Integrate the ordering**

Add an optional clock to `TimetablePage` and use it from both time update sites:

```dart
const TimetablePage({
  super.key,
  this.controller,
  this.stationDataSource,
  this.now,
});

final DateTime Function()? now;

DateTime _currentTime() => widget.now?.call() ?? DateTime.now();

// initState
_now = _currentTime();

// periodic refresh
if (mounted) setState(() => _now = _currentTime());
```

Replace the inline `dayOffset`/`departureTime` sort with:

```dart
final matchingSchedules = _searchQuery.isEmpty
    ? raw
    : raw.where((schedule) {
        final query = _searchQuery.toLowerCase();
        return schedule.trainName.toLowerCase().contains(query) ||
            schedule.route.toLowerCase().contains(query) ||
            schedule.stationName.toLowerCase().contains(query);
      });
final filteredSchedules = ScheduleStatusCalculator.orderByRelevance(
  schedules: matchingSchedules,
  now: _now,
);
```

Keep the existing next-upcoming calculation and all card/status UI unchanged.

- [ ] **Step 4: Run focused tests**

Run:

```powershell
flutter test test/schedule_status_test.dart test/timetable_page_catalog_test.dart
```

Expected: all focused tests pass.

- [ ] **Step 5: Run regression checks**

Run:

```powershell
flutter analyze
flutter test
```

Expected: analyzer reports no issues and the full Flutter suite passes.

- [ ] **Step 6: Reload the emulator**

Send a hot restart to the active `flutter run` session and verify the application remains the resumed Android activity. Open the timetable page and confirm the nearest upcoming service is the first card while passed cards are below it.
