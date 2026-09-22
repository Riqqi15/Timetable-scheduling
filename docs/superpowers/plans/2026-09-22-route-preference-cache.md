# Route Preference Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make switching among fastest, minimum-transfer, and accessible routes immediate after the first route load.

**Architecture:** `RouteController` preloads the two distinct backend preferences concurrently and stores them in an in-memory map. UI preferences resolve to one of those cached backend preferences, while a failed alternative is retried without replacing the current route with the full-page loader.

**Tech Stack:** Flutter, Dart `ChangeNotifier`, Flutter Test

---

### Task 1: Cache route alternatives in the controller

**Files:**
- Modify: `test/route_controller_test.dart`
- Modify: `lib/features/route_result/presentation/controllers/route_controller.dart`

- [ ] **Step 1: Write failing controller tests**

Add a repository fake that can complete or fail each `RoutePreference` independently. Assert that `load()` requests `fastest` and `minimumTransfers` once, switching among all UI preferences adds no calls, and a failed alternative leaves a successful route visible.

```dart
expect(repository.calls, [
  RoutePreference.fastest,
  RoutePreference.minimumTransfers,
]);
await controller.selectPreference(RoutePreference.minimumTransfers);
await controller.selectPreference(RoutePreference.accessible);
expect(repository.calls, hasLength(2));
expect(controller.state, RouteViewState.success);
```

- [ ] **Step 2: Run the focused test and verify failure**

Run: `flutter test test/route_controller_test.dart`

Expected: FAIL because `load()` currently requests only `fastest` and preference changes request the backend again.

- [ ] **Step 3: Implement the route cache**

Add controller state equivalent to:

```dart
final Map<RoutePreference, RoutePlan> _cache = {};
bool _isRefreshingPreference = false;
String? _preferenceError;

RoutePreference _backendPreference(RoutePreference value) =>
    value == RoutePreference.minimumTransfers
        ? RoutePreference.minimumTransfers
        : RoutePreference.fastest;
```

During `load`, clear the cache and fetch `fastest` plus `minimumTransfers` concurrently. Store each success independently. Use a cached plan in `selectPreference`; retry only a missing plan while leaving `_state` as `success` whenever `_route` is non-null. Prevent duplicate requests for the same preference.

- [ ] **Step 4: Run the focused test and verify success**

Run: `flutter test test/route_controller_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit the controller change**

```bash
git add lib/features/route_result/presentation/controllers/route_controller.dart test/route_controller_test.dart
git commit -m "fix: cache route preference alternatives"
```

### Task 2: Keep route content visible during targeted retries

**Files:**
- Modify: `test/route_result_page_test.dart`
- Modify: `lib/features/route_result/presentation/pages/route_result_page.dart`

- [ ] **Step 1: Write a failing widget regression test**

Use a delayed minimum-transfer response, render an already available fastest route, select `Minim Transit`, and assert the route summary stays visible while a small keyed progress indicator is shown.

```dart
expect(find.text('134'), findsOneWidget);
expect(find.byKey(const Key('route-preference-progress')), findsOneWidget);
expect(find.byType(CircularProgressIndicator), findsNothing);
```

- [ ] **Step 2: Run the widget test and verify failure**

Run: `flutter test test/route_result_page_test.dart`

Expected: FAIL because the current state replaces the page with a full-screen progress indicator.

- [ ] **Step 3: Render non-blocking preference status**

Keep `_RouteContent` mounted whenever `controller.route` is available. Insert a compact `LinearProgressIndicator` with key `route-preference-progress` below the filters when `isRefreshingPreference` is true. Render a small inline retry/error message when `preferenceError` is present.

- [ ] **Step 4: Run route tests**

Run: `flutter test test/route_controller_test.dart test/route_result_page_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit the UI regression fix**

```bash
git add lib/features/route_result/presentation/pages/route_result_page.dart test/route_result_page_test.dart
git commit -m "fix: keep route visible while changing mode"
```

### Task 3: Verify route caching

**Files:**
- Verify only

- [ ] **Step 1: Run static analysis**

Run: `flutter analyze`

Expected: `No issues found!`

- [ ] **Step 2: Run the full Flutter suite**

Run: `flutter test`

Expected: all tests pass.

