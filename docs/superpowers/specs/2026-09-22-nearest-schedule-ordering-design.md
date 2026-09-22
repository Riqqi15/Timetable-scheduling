# Nearest Schedule Ordering Design

## Goal

Make the timetable immediately useful at the current device time. Upcoming departures must appear first, while departures that have already passed remain available at the bottom of the list.

## Scope

- Use the phone's local `DateTime.now()` value already refreshed by `TimetablePage` every 30 seconds.
- Apply ordering after the existing search, station, train type, and weekday/weekend filters.
- Do not change the API response order, database records, or timetable import.
- Keep every schedule visible.

## Ordering Rules

1. Valid schedules that have not passed come first.
2. Active schedules are ordered by their calculated departure timestamp, earliest first.
3. Passed schedules follow active schedules.
4. Passed schedules are ordered by departure timestamp descending, so the most recently passed service appears first and the oldest service appears last.
5. Schedules with malformed or unavailable times appear after passed schedules and retain a stable deterministic order.
6. `dayOffset` participates in the departure timestamp so after-midnight services remain correctly ordered.

At 18:00, for example, an 18:05 service appears before 18:30. A 17:55 service appears in the passed section, while a 04:00 service is placed near the very bottom.

## Architecture

Add the ordering operation beside `ScheduleStatusCalculator` in the timetable domain service. The page supplies the filtered schedule list and its current `_now` value. The service returns a newly ordered list and does not mutate API data.

`TimetablePage` will replace its chronological `dayOffset`/`departureTime` sort with this domain operation. The existing 30-second timer triggers a rebuild, so schedules automatically move from active to passed without another API request.

## UI Behaviour

- The first active schedule remains marked as the next upcoming departure.
- Existing schedule cards, status labels, filters, scrolling, and localization remain unchanged.
- No new control or section header is required for this revision.

## Error Handling

Malformed time values must not crash sorting. They are assigned the unavailable status and placed last. Equal departure timestamps use their original order to avoid visible list jitter.

## Verification

Unit tests will cover:

- upcoming services before passed services;
- nearest upcoming service first;
- recently passed service before older passed services;
- `dayOffset` across midnight;
- unavailable time values last;
- stable ordering for equal departure timestamps.

A timetable page test will confirm that changing the supplied current time changes the visible card order without changing the underlying API data.
