# Selected Station Node Fill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace concentric station-selection rings with filled node states and replace the current-location ring with a compact localized map-pin callout.

**Architecture:** Keep all map rendering in `SchematicMapPainter` and reuse its existing station geometry. Add one small state-color helper, render regular and pill nodes according to selected/origin precedence, and make the nearest-station overlay a callout only. Reuse Flutter Material Icons and existing ARB generation; add no dependencies.

**Tech Stack:** Flutter, Dart `CustomPainter`, Material Icons, Flutter localization ARB, `flutter_test` pixel rendering.

---

### Task 1: Lock localized current-location copy

**Files:**
- Modify: `lib/l10n/app_id.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_zh_Hans.arb`
- Modify: `lib/l10n/app_ar.arb`
- Modify: generated `lib/l10n/app_localizations*.dart`
- Test: `test/localization_catalog_test.dart`

- [ ] **Step 1: Add a failing exact-copy test**

Add a test that reads each ARB and expects `mapYouAreHere` to equal `Lokasi kamu`, `Your location`, `你的位置`, and `موقعك` for the supported locale files.

- [ ] **Step 2: Run the localization test and confirm it fails**

Run: `rtk flutter test test/localization_catalog_test.dart`

Expected: FAIL because the catalogs still contain the old “Kamu di sini” equivalents.

- [ ] **Step 3: Update ARB values and regenerate localization classes**

Change only `mapYouAreHere`, then run `rtk flutter gen-l10n`.

- [ ] **Step 4: Run the localization test and confirm it passes**

Run: `rtk flutter test test/localization_catalog_test.dart`

Expected: all localization catalog tests pass.

- [ ] **Step 5: Commit the localization slice**

Commit message: `feat: localize current location label`

### Task 2: Specify painter state behavior with regression tests

**Files:**
- Modify: `test/location_marker_painter_test.dart`

- [ ] **Step 1: Replace the old ring expectation with pixel-state tests**

Add rendering assertions that verify:

```dart
expect(selectedCrop, containsColor(AppColors.primaryPurple));
expect(originCrop, containsColor(AppColors.kaiBlue));
expect(selectedAndOriginCrop, containsColor(AppColors.primaryPurple));
expect(locationNodeNeighborhood, baselineNodeNeighborhood);
expect(locationCalloutArea, containsColor(AppColors.kaiBlue));
```

Cover a regular coded node (`gondangdia`), a major/merged pill (`manggarai_bk`), and the location overlay. Keep the existing node-content preservation loop but expand its comparison area to prove no blue ring is painted around the node.

- [ ] **Step 2: Run the painter test and confirm it fails**

Run: `rtk flutter test test/location_marker_painter_test.dart`

Expected: FAIL because the painter still draws rings and white nodes.

### Task 3: Implement filled nodes, tinted pills, and the location callout

**Files:**
- Modify: `lib/shared/widgets/schematic_map_painter.dart`
- Test: `test/location_marker_painter_test.dart`

- [ ] **Step 1: Centralize state precedence**

Add a private helper returning purple for `isSelected`, KAI blue for `isFrom`, and null otherwise. Selection must win when both booleans are true.

- [ ] **Step 2: Remove concentric selection halos**

Delete `_drawSelectionHalo` and its three callers. Do not replace it with another ring or glow.

- [ ] **Step 3: Render regular station states**

For selected/origin coded nodes, use a radius 12% larger than `stationNodeRadius`, draw one 2 px white keyline, draw a solid state-color fill, and paint the code white. For code-less nodes, use the same fill/keyline with a small white center dot. Preserve the existing unselected rendering verbatim.

- [ ] **Step 4: Render major and merged hub states**

For selected/origin pills, fill with the state color at 10% opacity, use a 3 px state-color border, and render the hub name in the state color. Preserve existing white/neutral rendering when inactive.

- [ ] **Step 5: Replace the nearest-station marker and label**

Remove `_drawNearestStationMarker`. Update `_drawNearestStationLabel` to draw a white rounded callout with `Icons.location_on_outlined`, blue icon/text, 1.5 px translucent blue border, 10 px radius, 3 px shadow, and a small bordered pointer. Center it above the existing nearest-station geometry and clamp its horizontal bounds to the painter size. The overlay must never modify node fill.

- [ ] **Step 6: Run focused painter tests**

Run: `rtk flutter test test/location_marker_painter_test.dart`

Expected: all painter state and overlay tests pass.

- [ ] **Step 7: Commit the painter slice**

Commit message: `feat: simplify selected station map states`

### Task 4: Verify integration and emulator rendering

**Files:**
- Verify only; no planned source changes.

- [ ] **Step 1: Run formatter and static analysis**

Run: `rtk dart format lib/shared/widgets/schematic_map_painter.dart test/location_marker_painter_test.dart test/localization_catalog_test.dart`

Run: `rtk flutter analyze`

Expected: no analysis issues.

- [ ] **Step 2: Run affected map and localization tests**

Run: `rtk flutter test test/location_marker_painter_test.dart test/station_location_safety_test.dart test/station_map_contract_test.dart test/localization_catalog_test.dart`

Expected: all tests pass.

- [ ] **Step 3: Run the complete Flutter test suite**

Run: `rtk flutter test`

Expected: zero failures.

- [ ] **Step 4: Hot restart the connected emulator**

Use the active Flutter session when available; otherwise run `rtk flutter run -d emulator-5554`. Inspect a regular node and Manggarai with and without the current-location overlay.

- [ ] **Step 5: Commit any test-only corrections**

Commit only if verification required a source/test correction; otherwise leave the previous implementation commit as the final code commit.
