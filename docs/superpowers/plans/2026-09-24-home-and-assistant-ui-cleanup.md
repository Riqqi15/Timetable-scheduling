# Home and Assistant UI Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Collapse successful next-train lists by default and remove the unavailable Assistant wake-word card and its dead controller state.

**Architecture:** Keep timetable loading and voice recognition flows unchanged. Store only the currently expanded station name inside the next-train widget, and delete the unsupported wake-word surface from the Assistant UI and controller.

**Tech Stack:** Flutter, Dart, `flutter_test`

---

### Task 1: Make the next-train board collapsible

**Files:**
- Modify: `test/home_next_train_test.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`

- [x] **Step 1: Write the failing collapse interaction test**

Update `home shows real departures for every nearest-station direction` so the successful list is initially absent, then verify opening and closing:

```dart
expect(find.text('Kereta berikutnya dari Manggarai'), findsOneWidget);
expect(find.byKey(const ValueKey('next-train-direction-Cikini')), findsNothing);
expect(find.text('KA 101 · 18:05'), findsNothing);

await tester.tap(find.byKey(const Key('next-train-toggle')));
await tester.pumpAndSettle();

expect(find.byKey(const ValueKey('next-train-direction-Cikini')), findsOneWidget);
expect(find.byKey(const ValueKey('next-train-direction-Tebet')), findsOneWidget);
expect(find.text('KA 101 · 18:05'), findsOneWidget);
expect(find.text('KA 202 · 18:08'), findsOneWidget);

await tester.tap(find.byKey(const Key('next-train-toggle')));
await tester.pumpAndSettle();
expect(find.byKey(const ValueKey('next-train-direction-Cikini')), findsNothing);
```

- [x] **Step 2: Run the focused test and verify it fails**

Run:

```powershell
flutter test test/home_next_train_test.dart
```

Expected: FAIL because successful departures are still visible initially and `next-train-toggle` does not exist.

- [x] **Step 3: Implement the local expansion state**

Convert `_NextTrainBoard` into a `StatefulWidget`. Store `String? _expandedStationName`; consider the board expanded only when the controller is successful, its station name is non-null, and it equals `_expandedStationName`.

Add a semantic `InkWell` header with:

```dart
key: const Key('next-train-toggle'),
onTap: canToggle ? _toggle : null,
```

Use `AnimatedRotation` with `Icons.keyboard_arrow_down_rounded` and wrap the departure body in `AnimatedSize`. Keep loading, idle, empty, error, refresh progress, and refresh error content visible.

- [x] **Step 4: Run the focused test and verify it passes**

Run:

```powershell
flutter test test/home_next_train_test.dart
```

Expected: PASS.

- [x] **Step 5: Commit the next-train change**

```powershell
git add lib/features/home/presentation/pages/home_page.dart test/home_next_train_test.dart
git commit -m "feat: collapse next train board by default"
```

### Task 2: Remove the unavailable wake-word surface

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `test/assistant_controller_test.dart`
- Modify: `lib/features/assistant/presentation/pages/assistant_page.dart`
- Modify: `lib/features/assistant/presentation/controllers/assistant_controller.dart`

- [x] **Step 1: Update tests to require the wake-word card to be absent**

In the Assistant accessibility test, replace wake-word assertions with:

```dart
expect(find.text('Dengarkan "Halo Asisten"'), findsNothing);
expect(
  find.text('Belum tersedia. Ketuk mikrofon untuk berbicara.'),
  findsNothing,
);
expect(find.byKey(const Key('wake-word-switch')), findsNothing);
```

Keep the primary microphone semantic tap assertion. Delete the separate widget test `Assistant does not pretend unsupported wake word is active`. Rename the first controller test to `starts ready` and remove its wake-word calls.

- [x] **Step 2: Run focused tests and verify they fail**

Run:

```powershell
flutter test test/assistant_controller_test.dart test/widget_test.dart
```

Expected: FAIL because the wake-word card is still rendered.

- [x] **Step 3: Remove the wake-word UI and controller state**

Delete `_buildWakeWordSetting`, its call and spacer, and the wake-word cleanup branch in `AssistantPage.dispose`. Delete `wakeWordEnabled` and `toggleWakeWord` from `AssistantController`. Do not alter microphone, speech recognition, or conversation code.

- [x] **Step 4: Run focused tests and verify they pass**

Run:

```powershell
flutter test test/assistant_controller_test.dart test/widget_test.dart
```

Expected: PASS.

- [x] **Step 5: Run final verification**

Run:

```powershell
flutter analyze
flutter test
```

Expected: analysis reports no issues and all tests pass.

- [x] **Step 6: Commit the Assistant cleanup**

```powershell
git add lib/features/assistant/presentation/pages/assistant_page.dart lib/features/assistant/presentation/controllers/assistant_controller.dart test/assistant_controller_test.dart test/widget_test.dart docs/superpowers/plans/2026-09-24-home-and-assistant-ui-cleanup.md
git commit -m "feat: remove unavailable assistant wake word"
```
