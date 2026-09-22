# Nearest-Station Next Train Design

## Problem

The home page currently builds `Next Train` cards from hard-coded station examples and generated fallback values. Destinations, countdowns, travel durations, and platforms can therefore be unrelated to the timetable or the current time. The cards also mix directions without explaining which side of the route each train serves.

## Goal

Show timetable-backed upcoming KRL departures for the single station nearest to the user's verified location. Include every valid travel direction from that station and separate the results by direction so opposite trains are not confused with one another.

## Scope

- Use only the nearest station resolved by the existing location feature.
- Query official schedule data for that station and the current weekday or weekend service calendar.
- Show all directions that have a future departure.
- Group directions by the next station in each train's stop sequence.
- Remove hard-coded and generated `Next Train` values from the home page.
- Support the current KRL timetable dataset first. For unsupported LRT or MRT stations, show an honest unavailable state rather than fabricated data.

## Direction Model

The final destination alone is not sufficient to describe a direction because several services can share the same track direction but terminate at different stations. The backend will therefore return:

- `nextStation`: the first scheduled stop after the queried station;
- `destination`: the final scheduled stop for the service;
- `direction`: the timetable service direction when available.

The mobile app groups departures by `nextStation`. Each item still displays its final destination. For example, services from Manggarai that next stop at Cikini form one direction group, while services whose next stop is Tebet form another group. Only directions proven by the stop sequence are shown.

## Data Flow

1. The existing location service resolves the user's nearest schematic station.
2. The home controller requests schedules for that station, KRL, and the correct weekday/weekend calendar.
3. The backend finds the queried stop within each train service and derives the next stop from its ordered stop sequence.
4. The app discards departures earlier than the device's current Jakarta time.
5. Remaining departures are grouped by `nextStation`, sorted chronologically within each group, and the nearest one or two departures per direction are displayed.
6. Countdown labels are recalculated locally every minute without repeatedly requesting the backend.
7. Schedules are refreshed when the nearest station changes, the service day changes, the user explicitly retries, or the cached data becomes stale.

## Display

The section heading identifies the nearest station. Every direction group shows:

- `Arah <next station>`;
- final destination;
- train number;
- scheduled departure time;
- time remaining;
- platform when supplied by a platform rule.

Groups are ordered by their earliest upcoming departure. A missing platform is displayed as `Peron belum tersedia`; it is never guessed.

## Loading and Failure Behaviour

- Keep the home page and map visible while schedules load.
- Use a compact skeleton or progress indicator only inside the `Next Train` section.
- If GPS has not identified a station safely, ask the user to enable or retry location rather than selecting a station arbitrarily.
- If the station is known but no supported schedule exists, show `Jadwal belum tersedia untuk stasiun ini`.
- If the request fails, retain any non-expired cached result and offer a retry action.
- Never fall back to hard-coded destinations, countdowns, durations, or platforms.

## Components

### Backend Schedule Response

For a station-scoped KRL query, derive and return `nextStation`, `destination`, and `direction` from the same service and ordered stop sequence used for the departure. Terminal services with no next stop are excluded because they cannot be boarded onward from that station.

### Home Next Train Controller

Owns loading, cached schedules, refresh timing, time filtering, and direction grouping. Location resolution remains the responsibility of the existing location component.

### Home Page

Renders controller state and direction groups. It no longer owns station-specific timetable examples or manufactures fallback departures.

## Testing

- A station query returns the correct next stop and final destination from the service sequence.
- A terminal stop is not returned as a boardable onward departure.
- Past departures are excluded using Jakarta local time and `dayOffset`.
- Weekday and weekend queries use the correct service calendar.
- Departures with the same next stop are grouped together; opposite directions remain separate.
- Every valid direction with a future service is represented.
- Results are ordered by nearest departure and limited per direction.
- Missing platform data renders the unavailable label.
- Loading and errors do not replace the full home page.
- Unsupported stations never receive generated schedule data.

## Out of Scope

- Live train positions or delay predictions; countdowns are schedule-based.
- Fabricating LRT or MRT schedules while official data is unavailable.
- Selecting a manually chosen station instead of the GPS-derived nearest station.
