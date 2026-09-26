# Floating App Notice Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render every transient `AppNotice` as a contextual floating overlay without moving the current page.

**Architecture:** Keep the existing `AppNotice.show` API and replace its `MaterialBanner` and `SnackBar` implementations with one root `OverlayEntry`. A small stateful overlay widget owns entrance/exit animation, timeout, tap/swipe dismissal, safe-area positioning, and single-notice replacement. Call sites continue to select top placement explicitly; local feedback uses the bottom default.

**Tech Stack:** Flutter, Dart, `OverlayEntry`, `flutter_test`

---

### Task 1: Lock the overlay behavior with regression tests

**Files:**
- Modify: `test/app_notice_test.dart`
- Modify: `test/app_notice_usage_test.dart`

- [ ] **Step 1: Replace framework-component expectations with overlay expectations**

In `test/app_notice_test.dart`, record the harness body position before showing a notice, then assert the same position while the notice is visible:

```dart
final bodyTop = tester.getTopLeft(find.byKey(const Key('notice-harness-body')));
await tester.tap(find.text('Show success'));
await tester.pumpAndSettle(const Duration(milliseconds: 250));

expect(find.byType(MaterialBanner), findsNothing);
expect(find.byType(SnackBar), findsNothing);
expect(find.byKey(const Key('app_notice_success')), findsOneWidget);
expect(
  tester.getTopLeft(find.byKey(const Key('notice-harness-body'))),
  bodyTop,
);
```

Give the harness body `Key('notice-harness-body')`. Add tests for bottom placement, tap dismissal, automatic dismissal, replacement, semantic live-region behavior, and long multilingual text at `textScale: 2`.

- [ ] **Step 2: Forbid direct banners and snackbars in feature UI**

Change the static scan in `test/app_notice_usage_test.dart` to report either component:

```dart
for (final match in RegExp(
  r'\b(?:SnackBar|MaterialBanner)\s*\(',
).allMatches(source)) {
  final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
  violations.add('${file.path}:$line');
}
```

- [ ] **Step 3: Run the focused tests and verify they fail**

Run:

```powershell
flutter test test/app_notice_test.dart test/app_notice_usage_test.dart
```

Expected: FAIL because the current top notice is a `MaterialBanner`, the bottom notice is a `SnackBar`, and the top notice changes body geometry.

### Task 2: Replace Scaffold feedback with one floating overlay

**Files:**
- Modify: `lib/shared/widgets/app_notice.dart`
- Test: `test/app_notice_test.dart`

- [ ] **Step 1: Replace `MaterialBanner` and `SnackBar` creation**

Resolve the root overlay and replace the active entry before inserting the next one:

```dart
final overlay = Overlay.maybeOf(context, rootOverlay: true);
if (overlay == null) return;

_removeActiveEntry();
late final OverlayEntry entry;
entry = OverlayEntry(
  builder: (overlayContext) => _AppNoticeOverlay(
    message: trimmedMessage,
    type: type,
    placement: placement,
    duration: resolvedDuration,
    onDismiss: () => _removeEntry(entry),
  ),
);
_activeEntry = entry;
overlay.insert(entry);
```

Keep `_durationFor` unchanged. `_removeEntry` must check identity and mounted state before removing and disposing the entry.

- [ ] **Step 2: Implement animated safe-area positioning**

Create `_AppNoticeOverlay` as a `StatefulWidget` with `SingleTickerProviderStateMixin`. Use a 220 ms entrance and 160 ms exit, `FadeTransition`, and `SlideTransition`. Position top notices at `MediaQuery.paddingOf(context).top + 12`. Mirror the app navbar calculation for bottom notices: `72 + 28 * (textScale - 1).clamp(0, 1)`, then add the device bottom safe area and 12 pixels. This keeps the overlay above the custom navbar even with large system text.

The returned overlay tree must occupy only the card area:

```dart
return Positioned(
  left: 16,
  right: 16,
  top: placement == AppNoticePlacement.top ? topInset + 12 : null,
  bottom: placement == AppNoticePlacement.bottom
      ? bottomInset + navHeight + 12
      : null,
  child: FadeTransition(
    opacity: _animation,
    child: SlideTransition(
      position: _offset,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: _AppNoticeCard(message: message, type: type),
      ),
    ),
  ),
);
```

Start the dismissal timer after the entrance begins. Cancel it in `dispose`. For a top notice, an upward fling dismisses; for a bottom notice, a downward fling dismisses.

- [ ] **Step 3: Run focused tests and verify they pass**

Run:

```powershell
flutter test test/app_notice_test.dart test/app_notice_usage_test.dart
```

Expected: PASS with no `MaterialBanner`, no `SnackBar`, stable body geometry, and correct dismissal behavior.

- [ ] **Step 4: Commit the overlay engine**

```powershell
git add lib/shared/widgets/app_notice.dart test/app_notice_test.dart test/app_notice_usage_test.dart
git commit -m "fix: float app notices above page content"
```

### Task 3: Apply contextual top and bottom placement

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/features/profile/presentation/pages/active_ticket_detail_page.dart`
- Modify: `lib/features/profile/presentation/pages/completed_ticket_detail_page.dart`
- Modify: `lib/features/profile/presentation/pages/ticket_history_page.dart`

- [ ] **Step 1: Move the time-sensitive travel reminder to the top**

Pass the explicit placement in `lib/main.dart`:

```dart
AppNotice.show(
  context,
  message: reminder.message,
  type: AppNoticeType.warning,
  placement: AppNoticePlacement.top,
);
```

- [ ] **Step 2: Keep local ticket actions at the bottom**

Remove `placement: AppNoticePlacement.top` from ticket sharing, receipt download, and history clearing. They will use the bottom default because each message confirms an action initiated on the current page.

Do not change these existing placements:

- language success, alarm activation, and alarm deactivation remain top;
- language-save failure, checkout errors, route-origin validation, station voice errors, customer-service actions, staff-help actions, and help-center feedback remain bottom.

- [ ] **Step 3: Run affected widget tests**

Run:

```powershell
flutter test test/app_notice_test.dart test/widget_test.dart test/account_pages_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit contextual placement**

```powershell
git add lib/main.dart lib/features/profile/presentation/pages/active_ticket_detail_page.dart lib/features/profile/presentation/pages/completed_ticket_detail_page.dart lib/features/profile/presentation/pages/ticket_history_page.dart
git commit -m "fix: place app notices by interaction context"
```

### Task 4: Verify and run the mobile result

**Files:**
- Modify: `docs/superpowers/plans/2026-09-26-floating-app-notice-overlay.md`

- [ ] **Step 1: Run mechanical UI detection**

Run:

```powershell
node C:\Users\riyadh\.agents\skills\impeccable\scripts\detect.mjs --json lib/shared/widgets/app_notice.dart
```

Review findings for contrast, overflow, arbitrary spacing, safe-area positioning, and touch targets. Fix only findings relevant to the notice overlay.

- [ ] **Step 2: Run final verification**

Run:

```powershell
flutter analyze
flutter test
git diff --check
```

Expected: analysis reports no issues, every test passes, and `git diff --check` prints no errors.

- [ ] **Step 3: Launch the app with the local backend**

Verify `GET http://127.0.0.1:3000/health`, apply `adb reverse tcp:3000 tcp:3000`, launch Flutter on the active emulator, and trigger the language-change notice. The page header must remain in its original position while the notice floats above it.

- [ ] **Step 4: Commit the completed checklist**

```powershell
git add -f docs/superpowers/plans/2026-09-26-floating-app-notice-overlay.md
git commit --amend --no-edit
```
