# Cross-feature QA Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce an evidence-backed bug audit for the Flutter app, Node backend, localization, responsive layouts, integrations, and camera lifecycle before APK demonstration.

**Architecture:** Automated checks establish a reproducible baseline first. Widget and source-contract tests then cover cross-cutting risks that can be simulated, followed by emulator smoke testing and a clearly separated physical-device safety checklist. Findings are recorded by severity with reproduction and verification evidence.

**Tech Stack:** Flutter analyzer/tests, Dart widget tests, Node/Vitest/TypeScript, Android emulator/ADB, Markdown audit report.

---

### Task 1: Establish the automated baseline

**Files:**
- Create: `docs/qa/2026-09-22-cross-feature-audit-report.md`

- [ ] Run `flutter analyze` and record the exit result.
- [ ] Run `flutter test --reporter compact` and record the passed-test count.
- [ ] Run `npm test -- --run` inside `timetable_backend` and record the passed-test count.
- [ ] Run `npm run build` inside `timetable_backend` and record the exit result.
- [ ] Record the active branch, commit, and dirty-worktree status without writing secrets or `.env` values.
- [ ] Commit the baseline report with `docs: record cross-feature QA baseline`.

### Task 2: Audit cross-cutting contracts

**Files:**
- Create: `test/cross_feature_contract_test.dart`
- Modify: `docs/qa/2026-09-22-cross-feature-audit-report.md`

- [ ] Add a test that confirms production UI has no direct `SnackBar` construction outside `AppNotice`.
- [ ] Confirm every supported locale (`id`, `en`, `zh`, `ar`) remains registered in `AppLocalizations.supportedLocales`.
- [ ] Confirm the app theme is light-only and does not register an unintended dark theme.
- [ ] Confirm camera code does not write image bytes to a file, database, or Neon client.
- [ ] Run the contract tests and classify every failure before changing production code.
- [ ] Commit verified fixes separately by feature; do not combine unrelated bugs.

### Task 3: Responsive and localization matrix

**Files:**
- Modify existing focused tests under `test/` where the affected page already has a harness.
- Modify: `docs/qa/2026-09-22-cross-feature-audit-report.md`

- [ ] Exercise 320x640, 360x800, and 412x915 viewports at text scales 1.0, 1.3, and 2.0.
- [ ] Exercise Indonesian, English, Mandarin Simplified, and Arabic including RTL layout.
- [ ] Cover home/map, filters, route result, tickets, assistant, profile, language, and help flows.
- [ ] For every overflow or inaccessible control, add a failing test before the minimal fix.
- [ ] Re-run the affected test and the full Flutter suite after each fix batch.

### Task 4: Emulator integration smoke test

**Files:**
- Modify: `docs/qa/2026-09-22-cross-feature-audit-report.md`

- [ ] Confirm an Android emulator is online with `flutter devices`.
- [ ] Launch the current `dev1-riyadh` build with `flutter run`.
- [ ] Smoke test bottom navigation, map/filter, route search, timetable, tickets, assistant text flow, language switching, help center, and camera permission lifecycle.
- [ ] Capture runtime errors from the Flutter session and Android logs without recording credentials.
- [ ] Add reproduction steps, expected behavior, actual behavior, severity, and verification for each finding.

### Task 5: Physical-device safety checklist

**Files:**
- Modify: `docs/qa/2026-09-22-cross-feature-audit-report.md`

- [ ] Test one lower-end Android device and one modern Android device.
- [ ] Verify camera circles remain circular, full frame is visible, and portrait/landscape rotation aligns.
- [ ] Verify permission denied, permanently denied, background/resume, lens unavailable, offline backend, and low-light behavior.
- [ ] Measure camera latency median/p95 and memory during an endless controlled loop.
- [ ] Confirm no camera frames are persisted and no safety status says the path is safe merely because nothing was detected.
- [ ] Mark physical-only checks as pending until real-device evidence exists; never infer a pass from emulator results.

## Severity rubric

- **Critical:** safety risk, data loss, or unusable application.
- **High:** primary flow fails or gives incorrect travel information.
- **Medium:** feature remains usable with degraded accuracy or recovery.
- **Low:** cosmetic issue with no incorrect outcome.

## Completion rule

The audit is complete only when automated and emulator findings are resolved or explicitly accepted, while physical-device-only items remain visibly marked pending until measured on real hardware.
