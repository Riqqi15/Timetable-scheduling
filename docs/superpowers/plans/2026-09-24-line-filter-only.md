# Line Filter Only Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the unused area filter from the home map drawer and leave the existing transit-line filter as its only filter section.

**Architecture:** Keep the current drawer and line-filter state unchanged. Delete only the area-specific widget tree and callback, then update the existing widget tests to enforce the simpler drawer contract.

**Tech Stack:** Flutter, Dart, `flutter_test`

---

### Task 1: Enforce the line-only drawer contract

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `test/home_filter_safe_area_test.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`

- [ ] **Step 1: Update the home widget test to require a line-only drawer**

Replace the drawer assertions with:

```dart
expect(find.text('Filter Kawasan'), findsNothing);
expect(find.text('Seluruh Jabodetabek'), findsNothing);
expect(find.text('Filter Jalur Transportasi'), findsOneWidget);
```

- [ ] **Step 2: Replace the obsolete area-notice test**

Replace `coming-soon feedback closes the filter before appearing` with:

```dart
testWidgets('drawer exposes only transit line filters', (tester) async {
  tester.view.physicalSize = const Size(390, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  appRouter.go('/');
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.menu_rounded));
  await tester.pumpAndSettle();

  expect(find.text('Filter Kawasan'), findsNothing);
  expect(find.text('Jakarta Pusat'), findsNothing);
  expect(find.text('Filter Jalur Transportasi'), findsOneWidget);
  expect(
    find.byKey(const ValueKey('home-filter-bogor')),
    findsOneWidget,
  );
});
```

- [ ] **Step 3: Run focused tests and verify they fail**

Run:

```powershell
flutter test test/widget_test.dart test/home_filter_safe_area_test.dart
```

Expected: FAIL because the area section is still rendered.

- [ ] **Step 4: Delete the area UI and callback**

In `home_page.dart`, delete `_showAreaComingSoon`, the area `ExpansionTile`, and the divider immediately following it. Preserve the existing line `ExpansionTile` unchanged so it becomes the first drawer child.

- [ ] **Step 5: Run focused tests and verify they pass**

Run:

```powershell
flutter test test/widget_test.dart test/home_filter_safe_area_test.dart
```

Expected: PASS.

- [ ] **Step 6: Verify the project**

Run:

```powershell
flutter analyze
flutter test
```

Expected: analysis reports no issues and all tests pass.

- [ ] **Step 7: Commit the implementation**

```powershell
git add lib/features/home/presentation/pages/home_page.dart test/widget_test.dart test/home_filter_safe_area_test.dart
git commit -m "feat: remove area filter from map drawer"
```
