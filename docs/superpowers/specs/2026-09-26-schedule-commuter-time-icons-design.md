# Schedule Commuter Time Icons

## Goal

Replace the media-style departure and arrival symbols in each schedule card with commuter-train symbols that describe the information more clearly at a small mobile size.

## Design

Each time block uses a front-facing train icon followed by a small direction arrow on the same horizontal row:

- Departure: green train followed by an up-right arrow.
- Arrival: purple train followed by a down-left arrow.

The arrow is a separate icon beside the train. It must not overlap the train, label, or time. The existing localized labels remain the primary explanation, so the icons are supportive and never the only source of meaning.

## Scope

Only the two time-block icons in `ScheduleCard` change. Card layout, time values, localization, status calculation, route data, and schedule ordering remain unchanged. No new asset or package is required; the implementation uses Flutter Material icons already available in the project.

## Responsive Behavior

The train and arrow stay inside the label row. The label keeps its existing single-line ellipsis behavior on narrow screens, while the time remains on its own line below and cannot be covered by either icon.

## Accessibility

The visible localized labels continue to communicate departure and arrival. Decorative icons are grouped with the label and do not replace readable text or depend on color alone.

## Verification

- Widget tests confirm both time blocks render train and direction icons.
- Existing schedule-card tests continue to pass.
- Flutter analysis reports no issues.
- The card is visually checked at emulator width to confirm there is no overlap or clipping.
