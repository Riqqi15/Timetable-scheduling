# Floating App Notice Overlay Design

## Goal

Replace every transient in-app `AppNotice` banner and snackbar with a floating overlay that never changes the page layout.

## Scope

This change applies only to short-lived feedback shown through `AppNotice.show`, including success, information, warning, and error messages.

It does not replace:

- dialogs or bottom sheets that require a user decision;
- inline validation and persistent service-status messages;
- Android system notifications shown while the app is backgrounded or closed.

## Interaction

- A top notice appears 12 logical pixels below the device safe area with 16-pixel horizontal margins.
- A bottom notice appears above the device safe area and bottom navigation area with equivalent margins.
- The current page keeps its original position while the notice floats above it.
- A notice enters with a short slide-and-fade animation and exits with the reverse animation.
- Success messages remain visible for 3 seconds, information for 4 seconds, warnings for 5 seconds, and errors for 6 seconds.
- Tapping the card dismisses it immediately. A vertical swipe toward the nearest screen edge also dismisses it.
- Only one app notice may be visible. Showing another notice dismisses and replaces the current one.

## Placement Policy

Placement is selected by the event context, not by notice color or severity alone.

Use the top overlay for app-wide state changes and time-sensitive information that must remain visible above page controls:

- language applied;
- travel alarm activated or deactivated;
- an active travel reminder.

Use the bottom overlay for feedback caused by a control on the current page, positioned above the bottom navigation and gesture safe area:

- payment link or checkout failures;
- missing route-origin validation;
- station voice-guide failures;
- customer-service and staff-help actions;
- ticket sharing, receipt download, and history clearing;
- help-center actions.

Call sites keep choosing `AppNoticePlacement` explicitly when they need the top position. The default remains bottom for local feedback. Notice type continues to control color, icon, and duration only.

## Visual Treatment

The existing light, rounded card treatment is retained:

- success: light green with a green check icon;
- information: light blue with an information icon;
- warning: light amber with a warning icon;
- error: light red with an error icon.

The card uses the app theme typography, a 14-pixel radius, a restrained shadow, and no dark-mode variant because the app currently has no dark theme.

## Architecture

`AppNotice.show` will resolve the root Flutter `Overlay` from the supplied context and insert one `OverlayEntry`. The component owns the active entry so all existing call sites continue using the same API.

The overlay widget will own its animation and dismissal timer. Replacing a notice disposes the previous entry and timer before inserting the new entry. Top and bottom placement remain selectable through `AppNoticePlacement`, but neither placement uses `MaterialBanner`, `SnackBar`, or changes `Scaffold` geometry.

The overlay occupies only the card area, so controls elsewhere on the page remain interactive.

## Accessibility and Safety

- The message remains a semantic live region so assistive technology announces it.
- Text may wrap and grow with the system text scale instead of being truncated.
- Safe-area insets prevent overlap with status bars, display cutouts, gesture areas, and navigation controls.
- Motion is short and functional; the message remains understandable without relying on animation or color.
- Error messages remain visible longer than success messages.

## Verification

Widget tests will verify that:

- a top notice is rendered through an overlay, not a `MaterialBanner`;
- a bottom notice is rendered through an overlay, not a `SnackBar`;
- the page body's position is identical before, during, and after a notice;
- a second notice replaces the first;
- notices dismiss automatically and when tapped;
- long multilingual text and large text scale do not overflow;
- the semantic live region remains present.

The final implementation must also pass `flutter analyze`, focused notice tests, and the complete Flutter test suite.
