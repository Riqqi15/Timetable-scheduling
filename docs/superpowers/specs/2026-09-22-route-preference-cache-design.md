# Route Preference Cache Design

## Problem

The route result page replaces its content with a full-page loading indicator when the user changes between `Jalur biasa`, `Minim transit`, and `Aksesibel`. The controller requests the backend again whenever the selected option maps to a different backend preference. This makes a mobile interaction that should feel immediate appear slow and unstable.

## Goal

After the first route result load finishes, switching between all three route preferences must be immediate and must not hide the current route behind a full-page loading indicator.

## Scope

- Load and cache the two distinct backend route strategies: `FASTEST` and `MIN_TRANSFERS`.
- Use the cached `FASTEST` result for both `Jalur biasa` and `Aksesibel`.
- Keep accessibility presentation and guidance enabled only when `Aksesibel` is selected.
- Preserve the currently visible route if another route strategy fails to load.
- Do not change the backend API contract.

## Data Flow

1. When the route result page opens, the controller requests `FASTEST` and `MIN_TRANSFERS` concurrently.
2. Successful results are stored in an in-memory cache owned by the route controller.
3. The default route is rendered as soon as the initial loading operation completes.
4. Selecting a preference resolves its backend strategy and reads the corresponding route from the cache.
5. Selecting `Aksesibel` reads the cached `FASTEST` route and applies accessibility-specific UI behavior.
6. The cache is discarded when the route result controller is disposed.

## Loading and Failure Behaviour

- A full-page loading indicator is allowed only during the first route result load, when no route is available yet.
- Preference changes must never replace an existing route with a blank loading page.
- If one strategy fails during the initial parallel load, a successful strategy remains usable.
- Selecting a strategy whose initial request failed keeps the current route visible, retries only that missing strategy, and shows a small non-blocking progress or error message.
- Duplicate requests for a strategy already cached or currently being fetched are prevented.

## Components

### Route Controller

- Owns the route cache keyed by backend route preference.
- Maps the three UI preferences to the two backend strategies.
- Coordinates parallel initial loading and targeted retries.
- Exposes whether a preference is being refreshed without changing the main view state to full-page loading.

### Route Result Page

- Continues showing the current route while a missing alternative is fetched.
- Uses the full-page loader only when no usable route exists.
- Shows a compact, non-blocking status when an alternative is being fetched or cannot be loaded.

## Testing

- Initial loading requests `FASTEST` and `MIN_TRANSFERS` exactly once each.
- Switching among all three preferences after loading sends no additional backend requests.
- `Aksesibel` reuses the `FASTEST` route while preserving its distinct accessibility state.
- Failure of one alternative does not remove a successfully loaded route.
- Retrying a missing alternative does not enter the full-page loading state.
- Existing route result and route preference tests continue to pass.

## Out of Scope

- Changing route-generation algorithms in the backend.
- Persisting route alternatives across separate route searches or application restarts.
- Reworking schedule or `Next Train` calculations; those use a separate timetable design.
