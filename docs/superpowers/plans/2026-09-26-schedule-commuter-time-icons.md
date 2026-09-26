# Schedule Commuter Time Icons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the schedule card's play and stop symbols with compact commuter-train and direction icons that remain beside the label and never overlap the time.

**Architecture:** Keep the change inside the existing `ScheduleCard` widget. Extend its private `_TimeBlock` to render a train icon and a separate direction icon in the existing label row; no new component, package, asset, or data flow is needed.

**Tech Stack:** Flutter, Dart, Material Icons, `flutter_test`

---

### Task 1: Render commuter departure and arrival icons

**Files:**
- Create: `test/schedule_card_time_icons_test.dart`
- Modify: `lib/features/timetable/presentation/widgets/schedule_card.dart:195-272`

- [ ] **Step 1: Write the failing widget test**

Create `test/schedule_card_time_icons_test.dart` with a localized `ScheduleCard`, then assert that it contains two train icons, one north-east departure arrow, and one south-west arrival arrow:

```dart
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
```

- [ ] **Step 2: Run the focused test and confirm it fails**

Run:

```bash
flutter test test/schedule_card_time_icons_test.dart
```

Expected: FAIL because `ScheduleCard` still renders `Icons.play_arrow_rounded` and `Icons.stop_rounded`.

- [ ] **Step 3: Implement the minimal icon pair**

In `ScheduleCard`, pass a train icon and direction icon to each `_TimeBlock`:

```dart
_TimeBlock(
  label: l10n.departFromStation(schedule.stationName),
  value: schedule.departureTime,
  icon: Icons.train_rounded,
  directionIcon: Icons.north_east_rounded,
  color: trainColor,
),

_TimeBlock(
  label: l10n.estimatedArrival,
  value: schedule.arrivalTime,
  icon: Icons.train_rounded,
  directionIcon: Icons.south_west_rounded,
  color: AppColors.primaryPurple,
),
```

Add the required `directionIcon` field to `_TimeBlock` and render it directly after the train icon. Keep both inside the label row and keep the time in the existing row below:

```dart
const _TimeBlock({
  required this.label,
  required this.value,
  required this.icon,
  required this.directionIcon,
  required this.color,
});

final IconData directionIcon;

Row(
  children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 2),
    Icon(directionIcon, size: 10, color: color),
    const SizedBox(width: 4),
    Expanded(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),
```

- [ ] **Step 4: Format and run focused verification**

Run:

```bash
dart format lib/features/timetable/presentation/widgets/schedule_card.dart test/schedule_card_time_icons_test.dart
flutter test test/schedule_card_time_icons_test.dart test/schedule_card_border_test.dart test/schedule_card_status_test.dart
flutter analyze
```

Expected: all tests pass and analysis reports `No issues found!`.

- [ ] **Step 5: Check the emulator layout**

Hot restart the running Flutter app and open the schedule page. Confirm both icons stay in the label row, the label truncates rather than colliding, and the `22:24`/`22:50` time row remains unobstructed.

- [ ] **Step 6: Commit the implementation**

```bash
git add lib/features/timetable/presentation/widgets/schedule_card.dart test/schedule_card_time_icons_test.dart
git commit -m "style: use commuter icons for schedule times"
```
