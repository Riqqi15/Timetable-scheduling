# Selected Station Node Fill Design

## Goal

Make the selected station immediately recognizable without the current target-like stack of concentric rings. The selected, origin, and current-location states must remain distinct over every commuter line color and must not change the existing map geometry.

## Visual Rules

### Regular station node

- Replace the double selection ring with a solid `AppColors.primaryPurple` fill.
- Render the station code in white.
- Add one 2 px white keyline around the filled node so it remains separated from the rail line behind it.
- Increase only the selected node radius by 12%; do not move the node or alter the line layout.
- Keep the selected station name purple and bold.
- Do not draw any additional ring or outer halo.

### Origin station

- Use the same filled treatment with `AppColors.kaiBlue` instead of purple. `AppColors.primaryBlue` is intentionally not used because it is currently a compatibility alias for purple.
- Render its code in white and retain the thin white keyline.
- If a station is both the origin and the currently selected station, the selected purple state takes precedence.

### Major and merged transit hubs

- Do not fill the entire station-name pill with solid purple because it would dominate nearby lines and labels.
- Use `AppColors.primaryPurple` at 10% opacity as the background, with a 3 px purple border and purple text for the selected state.
- Use the equivalent 10% blue background, 3 px blue border, and blue text for the origin state.
- Remove the concentric selection halo from these hubs.

### Stations without a code

- Use a solid selected-state fill with a small white center dot.
- Apply the same purple/blue precedence rules as coded nodes.

### Current-location marker

- Replace the blue ring and solid-blue label with a compact white callout.
- Use Flutter's `Icons.location_on_outlined`, followed by the localized label: `Lokasi kamu` (Indonesian), `Your location` (English), `你的位置` (Simplified Chinese), and `موقعك` (Arabic).
- Draw the icon and text in `AppColors.kaiBlue`.
- Use a 1.5 px blue border at 46% opacity, a 10 px corner radius, and a shadow with 3 px elevation at 12% opacity.
- Add a small white pointer with the same blue border to anchor the callout to the station; do not draw a separate connector line or any ring around the node.
- Center the callout above a regular node or transit pill using the existing nearest-station geometry. Preserve the existing clearance calculations for station-code badges.
- Clamp the callout horizontally inside the map canvas so long localized labels do not clip.
- The current-location marker is an overlay only and never changes the node fill:
  - Location only: keep the station's normal node treatment and show the callout.
  - Selected plus location: keep the purple selected treatment and show the callout.
  - Origin plus location: keep the blue origin treatment and show the callout.
- Draw the callout after station nodes and labels so it remains legible without covering the node code or station name.

## Interaction and Accessibility

- Keep the existing hit-testing geometry or enlarge only the invisible touch target; visual enlargement must not change line geometry.
- Selection must be identifiable through fill, contrast, and size, not color alone.
- White code text and the white keyline must retain strong contrast against the selected fill.
- The current-location state remains identifiable through its map-pin icon and text, not blue color alone.
- Unselected stations and route-line colors remain unchanged.

## Scope

The change is limited to selected/origin station rendering, the nearest-station overlay in `SchematicMapPainter`, and the localized current-location copy. It does not redesign other station labels, alter line placement, change map zoom behavior, or modify route-selection logic.

## Verification

- Add or update painter tests for selected, origin, and selected-plus-origin precedence.
- Add or update marker tests for location only, selected plus location, and origin plus location.
- Verify regular coded nodes, nodes without codes, major hubs, and merged hubs.
- Verify that the current-location callout clears line-code badges on major and merged hubs and stays inside the map canvas.
- Run Flutter analysis and the relevant map/widget tests.
- Visually inspect the result on the Android emulator at normal and low zoom to confirm the node is clear without resembling a target.
