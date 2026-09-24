# Collapsible Next Train Board Design

## Goal

Reduce the initial height of the station detail panel by hiding successful next-train departures until the user chooses to view them.

## Interaction

- When departure data is successfully loaded, the next-train board is collapsed by default.
- The collapsed board shows the existing status dot, localized title, and a downward chevron.
- Tapping anywhere on the header expands the complete direction and departure list.
- Tapping the header again collapses the list.
- The chevron rotates to communicate the current state.
- Expansion and collapse use a short built-in Flutter animation.
- The expanded departure rows retain their existing navigation behavior.

## State handling

- Loading, idle/location-unconfirmed, empty, and error content remains visible because it explains why departures are unavailable and may contain a retry action.
- Only a successfully loaded departure list can be collapsed.
- Refresh progress and refresh errors remain visible while expanded or collapsed so background failures are not hidden.
- A new station selection resets the successful list to collapsed, avoiding unexpectedly tall station panels.

## Accessibility

- The header is one semantic button with the localized board title.
- Its semantic state exposes whether the list is expanded or collapsed.
- The touch target remains at least 48 logical pixels tall.
- Keyboard and screen-reader activation use the same toggle action as touch.

## Implementation

- Convert `_NextTrainBoard` from `StatelessWidget` to `StatefulWidget` and keep the name of the currently expanded station in local state.
- Treat the board as expanded only when that stored name matches the controller's current station, so a station change automatically returns to the collapsed state without another listener.
- Use `InkWell` for the header and `AnimatedRotation` for the chevron.
- Use `AnimatedSize` around the body so opening and closing does not jump.
- Keep the controller and schedule data flow unchanged.

## Testing

- Verify successful departures are absent initially.
- Verify tapping the header reveals every direction and departure.
- Verify a second tap hides them again.
- Verify loading, idle, empty, and error messages are not hidden by the collapsed state.
- Run Flutter analysis and the full test suite.

## Out of scope

- Showing a one-train preview while collapsed.
- Persisting expansion state between app launches.
- Changing timetable grouping, ordering, or backend requests.
