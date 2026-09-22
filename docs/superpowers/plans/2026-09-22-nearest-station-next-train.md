# Nearest-Station Next Train Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace generated home-page departures with real upcoming KRL schedules for the GPS-derived nearest station, grouped across every valid direction.

**Architecture:** The backend enriches station-scoped schedule records with next-stop and destination metadata derived from ordered stop sequences. Flutter parses that metadata into `TrainSchedule`, a focused `NextTrainController` filters and groups future departures, and `HomePage` receives nearest-station changes from `StationLocatedMap` and renders only controller-backed data.

**Tech Stack:** TypeScript, Express, Prisma, Node Test Runner, Flutter, Dart, Flutter Test

---

### Task 1: Derive direction metadata in the backend

**Files:**
- Create: `timetable_backend/src/domain/services/scheduleDirection.ts`
- Create: `timetable_backend/tests/scheduleDirection.test.ts`
- Modify: `timetable_backend/src/presentation/controllers/scheduleController.ts`

- [ ] **Step 1: Write failing direction tests**

Test a pure helper with the queried stop sequence and ordered service stops:

```ts
assert.deepEqual(resolveScheduleDirection(2, [
  { sequence: 1, stationName: 'Matraman' },
  { sequence: 2, stationName: 'Manggarai' },
  { sequence: 3, stationName: 'Cikini' },
  { sequence: 4, stationName: 'Jakarta Kota' },
]), { nextStation: 'Cikini', destination: 'Jakarta Kota' });
assert.equal(resolveScheduleDirection(4, stops), null);
```

- [ ] **Step 2: Run the backend test and verify failure**

Run from `timetable_backend`: `npm test -- --test-name-pattern="schedule direction"`

Expected: FAIL because the helper does not exist.

- [ ] **Step 3: Implement the pure helper**

Create a typed helper that sorts or consumes ordered stops, returns the first stop whose sequence is greater than the queried sequence, uses the last stop as destination, and returns `null` at a terminal stop.

- [ ] **Step 4: Enrich station-scoped schedule responses**

Select `sequence` for both the queried `TrainStopTime` and service stops. Exclude terminal records, then return:

```ts
nextStation: directionInfo.nextStation,
destination: directionInfo.destination,
direction: service.direction,
```

Do not alter the global schedule-list response contract.

- [ ] **Step 5: Run backend tests and build**

Run from `timetable_backend`:

```bash
npm test
npm run build
```

Expected: all tests pass and TypeScript compilation succeeds.

- [ ] **Step 6: Commit backend metadata**

```bash
git add timetable_backend/src/domain/services/scheduleDirection.ts timetable_backend/src/presentation/controllers/scheduleController.ts timetable_backend/tests/scheduleDirection.test.ts
git commit -m "feat: expose schedule direction metadata"
```

### Task 2: Parse schedule direction metadata in Flutter

**Files:**
- Modify: `lib/features/timetable/domain/entities/train_schedule.dart`
- Modify: `lib/features/timetable/data/models/train_schedule_model.dart`
- Modify: `test/timetable_remote_data_source_test.dart`

- [ ] **Step 1: Write a failing parsing test**

Extend the mocked station response with `nextStation`, `destination`, and `direction`, then assert all three values survive parsing.

```dart
expect(schedules.first.nextStation, 'Cikini');
expect(schedules.first.destination, 'Jakarta Kota');
expect(schedules.first.direction, 'NORTHBOUND');
```

- [ ] **Step 2: Run the parsing test and verify failure**

Run: `flutter test test/timetable_remote_data_source_test.dart`

Expected: FAIL because `TrainSchedule` lacks the fields.

- [ ] **Step 3: Add nullable metadata fields**

Add optional `nextStation`, `destination`, and `direction` constructor parameters and fields to `TrainSchedule`; parse nullable strings in `TrainScheduleModel.fromJson`. Existing schedule fixtures remain source-compatible.

- [ ] **Step 4: Run the parsing test**

Run: `flutter test test/timetable_remote_data_source_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit Flutter model support**

```bash
git add lib/features/timetable/domain/entities/train_schedule.dart lib/features/timetable/data/models/train_schedule_model.dart test/timetable_remote_data_source_test.dart
git commit -m "feat: parse train direction metadata"
```

### Task 3: Build the nearest-station next-train controller

**Files:**
- Create: `lib/features/home/presentation/controllers/next_train_controller.dart`
- Create: `test/next_train_controller_test.dart`

- [ ] **Step 1: Write failing grouping and time tests**

Use an injected schedule loader and clock. Cover weekday selection, removal of past departures, `dayOffset`, grouping by `nextStation`, chronological ordering, two results per direction, terminal/unsupported records, retained cached data on refresh failure, and one-minute countdown updates.

```dart
expect(controller.groups.map((group) => group.nextStation), ['Cikini', 'Tebet']);
expect(controller.groups.first.departures.length, 2);
expect(controller.groups.first.departures.first.minutesUntilDeparture, 5);
```

- [ ] **Step 2: Run the controller test and verify failure**

Run: `flutter test test/next_train_controller_test.dart`

Expected: FAIL because the controller does not exist.

- [ ] **Step 3: Implement focused state and grouping types**

Implement `NextTrainState`, `NextTrainDeparture`, `NextTrainDirectionGroup`, and `NextTrainController`. The controller calls the existing timetable use case with `station`, `trainType: 'KRL'`, and weekend state; only records with non-empty `nextStation` and `destination` are eligible. It uses schedule time plus `dayOffset`, keeps the first two departures per next-station group, and updates countdowns locally.

- [ ] **Step 4: Run controller tests**

Run: `flutter test test/next_train_controller_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit controller logic**

```bash
git add lib/features/home/presentation/controllers/next_train_controller.dart test/next_train_controller_test.dart
git commit -m "feat: group nearest station departures"
```

### Task 4: Publish nearest-station changes from the map

**Files:**
- Modify: `lib/features/home/presentation/widgets/station_located_map.dart`
- Modify: `test/station_location_safety_test.dart`

- [ ] **Step 1: Write a failing callback test**

Inject a location gateway, provide a nearby coordinate, and assert `onNearestStationChanged` receives the verified `StationGeoPoint`; assert it receives `null` when the verified location becomes unavailable.

- [ ] **Step 2: Run the safety test and verify failure**

Run: `flutter test test/station_location_safety_test.dart`

Expected: FAIL because the callback is absent.

- [ ] **Step 3: Add deduplicated callback delivery**

Add `ValueChanged<StationGeoPoint?>? onNearestStationChanged`. In the tracker listener, compare the current schematic station ID with the last published ID and schedule a post-frame callback only when it changes. Publish `null` when proximity is no longer verified.

- [ ] **Step 4: Run the safety test**

Run: `flutter test test/station_location_safety_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit location integration**

```bash
git add lib/features/home/presentation/widgets/station_located_map.dart test/station_location_safety_test.dart
git commit -m "feat: publish nearest station changes"
```

### Task 5: Replace generated home departures

**Files:**
- Modify: `lib/features/home/presentation/pages/home_page.dart`
- Modify: `lib/l10n/app_id.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`
- Create: `test/home_next_train_test.dart`

- [ ] **Step 1: Write failing widget tests**

Inject a `NextTrainController`, publish Manggarai as nearest station, and verify separate `Arah Cikini` and `Arah Tebet` groups, real train numbers and times, the unavailable platform label, inline loading, and retry/error states. Verify no schedule card is generated without a verified nearest station.

- [ ] **Step 2: Run the widget test and verify failure**

Run: `flutter test test/home_next_train_test.dart`

Expected: FAIL because `HomePage` still uses `_stationInfoMap` and `_getDynamicStationInfo`.

- [ ] **Step 3: Wire the controller into HomePage**

Allow an optional controller for tests and create the production controller from the existing timetable repository otherwise. Pass `onNearestStationChanged` to `StationLocatedMap`, call `loadStation` only when the verified nearest station changes, and dispose owned controllers and timers.

- [ ] **Step 4: Replace `_NextTrainBoard` data and states**

Remove `_DepartureInfo`, `_StationInfo`, `_stationInfoMap`, and `_getDynamicStationInfo`. Render grouped `NextTrainDeparture` values, compact section-only progress, empty/unavailable copy, and retry without hiding the map or station sheet. Display `Peron belum tersedia` for blank platform values.

- [ ] **Step 5: Generate localization code**

Run: `flutter gen-l10n`

Expected: generated localization classes include direction, loading, unavailable, retry, departure-time, and platform labels.

- [ ] **Step 6: Run home and timetable tests**

Run:

```bash
flutter test test/home_next_train_test.dart test/station_location_safety_test.dart test/timetable_remote_data_source_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit the real Next Train UI**

```bash
git add lib/features/home lib/l10n test/home_next_train_test.dart
git commit -m "feat: show real nearest station departures"
```

### Task 6: Verify the complete feature

**Files:**
- Verify only

- [ ] **Step 1: Run backend verification**

Run from `timetable_backend`: `npm test` and `npm run build`.

Expected: all tests and build pass.

- [ ] **Step 2: Run Flutter verification**

Run from repository root: `flutter analyze` and `flutter test`.

Expected: no analyzer issues and all tests pass.

- [ ] **Step 3: Exercise the emulator**

Restart the local backend and Flutter app. Simulate a location near Manggarai and verify the home page shows every future direction as separate next-stop groups, contains no fabricated fields, and leaves the map visible while schedules load.

