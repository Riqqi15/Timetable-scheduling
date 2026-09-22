# App Notice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace ad-hoc dark/default snackbars with one light, accessible, contextual notification component that does not obstruct primary controls.

**Architecture:** A shared `AppNotice` presenter owns category colors, icons, duration, semantics, and placement. Success feedback uses an automatically dismissed top `MaterialBanner`; ordinary information, warnings, and errors use a floating bottom `SnackBar` above the device inset. Existing feature pages only choose the message, category, and placement.

**Tech Stack:** Flutter Material 3, Dart, widget tests, existing `AppColors` theme tokens.

---

### Task 1: Shared notification presenter

**Files:**
- Create: `lib/shared/widgets/app_notice.dart`
- Create: `test/app_notice_test.dart`

- [ ] **Step 1: Write failing widget tests**

Create tests that open a notice from a `Scaffold` and assert:

```dart
testWidgets('success notice uses a light top banner', (tester) async {
  await tester.pumpWidget(noticeHarness());
  await tester.tap(find.text('Show success'));
  await tester.pump();
  expect(find.byType(MaterialBanner), findsOneWidget);
  expect(find.byKey(const Key('app_notice_success')), findsOneWidget);
  expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
});

testWidgets('error notice uses a floating bottom snackbar', (tester) async {
  await tester.pumpWidget(noticeHarness());
  await tester.tap(find.text('Show error'));
  await tester.pump();
  expect(find.byType(SnackBar), findsOneWidget);
  expect(find.byKey(const Key('app_notice_error')), findsOneWidget);
  expect(find.byIcon(Icons.error_rounded), findsOneWidget);
});
```

- [ ] **Step 2: Run tests and verify the missing presenter fails**

Run: `flutter test test/app_notice_test.dart`

Expected: compilation failure because `AppNotice` does not exist.

- [ ] **Step 3: Implement the shared presenter**

Create these public contracts:

```dart
enum AppNoticeType { success, info, warning, error }
enum AppNoticePlacement { top, bottom }

abstract final class AppNotice {
  static void show(
    BuildContext context, {
    required String message,
    AppNoticeType type = AppNoticeType.info,
    AppNoticePlacement placement = AppNoticePlacement.bottom,
    Duration? duration,
  });
}
```

Implementation requirements:

```dart
final resolvedDuration = duration ?? switch (type) {
  AppNoticeType.success => const Duration(seconds: 3),
  AppNoticeType.info => const Duration(seconds: 4),
  AppNoticeType.warning => const Duration(seconds: 5),
  AppNoticeType.error => const Duration(seconds: 6),
};
```

- Clear the current snackbar and material banner before presenting a replacement.
- Use a light surface for every category, a Material icon, system typography from `Theme.of(context).textTheme`, and `Semantics(liveRegion: true)`.
- Use a 14px radius and one soft offset shadow without a second border treatment.
- Allow wrapped RTL/CJK text and do not set a fixed notification width.
- The bottom snackbar uses `SnackBarBehavior.floating` and accounts for `MediaQuery.viewPadding.bottom`.
- The top banner is transparent outside the notice card and closes automatically after the resolved duration.

- [ ] **Step 4: Run the component tests**

Run: `flutter test test/app_notice_test.dart`

Expected: all notice component tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/app_notice.dart test/app_notice_test.dart
git commit -m "feat(ui): add contextual app notices"
```

### Task 2: Migrate feature feedback

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/features/assistant/presentation/pages/assistant_page.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`
- Modify: `lib/features/profile/presentation/pages/active_ticket_detail_page.dart`
- Modify: `lib/features/profile/presentation/pages/completed_ticket_detail_page.dart`
- Modify: `lib/features/profile/presentation/pages/help_center_page.dart`
- Modify: `lib/features/profile/presentation/pages/language_page.dart`
- Modify: `lib/features/profile/presentation/pages/ticket_history_page.dart`
- Modify: `lib/features/profile/presentation/widgets/help_flow_widgets.dart`
- Modify: `lib/features/search_station/presentation/pages/search_station_page.dart`
- Modify: `lib/features/tickets/presentation/pages/tickets_page.dart`
- Test: `test/app_notice_usage_test.dart`

- [ ] **Step 1: Add a failing source-contract test**

The test scans production Dart files and rejects direct construction of `SnackBar(` outside `app_notice.dart`:

```dart
expect(
  violations,
  isEmpty,
  reason: 'Feature UI must present feedback through AppNotice.',
);
```

- [ ] **Step 2: Run the contract test and verify existing call sites fail**

Run: `flutter test test/app_notice_usage_test.dart`

Expected: failure listing the current direct snackbar files.

- [ ] **Step 3: Replace direct snackbar calls with contextual notices**

Use these mappings:

```dart
AppNotice.show(
  context,
  message: message,
  type: AppNoticeType.success,
  placement: AppNoticePlacement.top,
);
```

- Success/top: language applied, alarm activated/deactivated, history cleared, receipt/share prepared.
- Error/bottom: language save failure and station voice-guide failure.
- Warning/bottom: incomplete station selection and travel reminder when it requires attention.
- Info/bottom: coming-soon filters, help actions, call-CS actions, and non-critical ticket information.
- Keep camera safety status in its persistent panel; do not route it through `AppNotice`.

- [ ] **Step 4: Run focused notification and affected feature tests**

Run:

```bash
flutter test test/app_notice_test.dart test/app_notice_usage_test.dart test/widget_test.dart test/language_page_test.dart test/ticket_checkout_page_test.dart
```

Expected: all focused tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib test/app_notice_usage_test.dart
git commit -m "refactor(ui): unify transient feedback"
```

### Task 3: Hardening and regression verification

**Files:**
- Modify if required: `test/app_notice_test.dart`

- [ ] **Step 1: Verify long and multilingual content**

Add widget coverage using a long Indonesian message, Mandarin text, and Arabic RTL text at a 2.0 text scale. Assert there are no framework exceptions:

```dart
expect(tester.takeException(), isNull);
expect(find.byKey(const Key('app_notice_info')), findsOneWidget);
```

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`

Expected: `No issues found!`

- [ ] **Step 3: Run the full Flutter suite**

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 4: Run the Impeccable detector once**

Run:

```bash
node C:/Users/riyadh/.agents/skills/impeccable/scripts/detect.mjs --json lib/shared/widgets/app_notice.dart
```

Expected: no unresolved design-rule violations.

- [ ] **Step 5: Commit any final hardening changes**

```bash
git add lib/shared/widgets/app_notice.dart test/app_notice_test.dart
git commit -m "test(ui): harden app notices"
```

## Self-review

- Spec coverage: top success feedback, bottom ordinary feedback, light-only surfaces, shared style, localization-safe wrapping, screen-reader announcement, and single-notice replacement are covered.
- Placeholder scan: no `TBD`, deferred implementation, or unspecified error-handling step remains.
- Type consistency: `AppNoticeType`, `AppNoticePlacement`, and `AppNotice.show` are identical across component and migration tasks.

Execution continues inline in the current session as already approved.
