# Selected Station Node Fill Design

## Goal

Make the selected station immediately recognizable without the current target-like stack of concentric rings. The treatment must remain readable over every commuter line color and must not change the existing map geometry.

## Visual Rules

### Regular station node

- Replace the double selection ring with a solid `AppColors.primaryPurple` fill.
- Render the station code in white.
- Add one 2 px white keyline around the filled node so it remains separated from the rail line behind it.
- Increase only the selected node radius by 12%; do not move the node or alter the line layout.
- Keep the selected station name purple and bold.
- Do not draw any additional ring or outer halo.

### Origin station

- Use the same filled treatment with `AppColors.primaryBlue` instead of purple.
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

## Interaction and Accessibility

- Keep the existing hit-testing geometry or enlarge only the invisible touch target; visual enlargement must not change line geometry.
- Selection must be identifiable through fill, contrast, and size, not color alone.
- White code text and the white keyline must retain strong contrast against the selected fill.
- Unselected stations and route-line colors remain unchanged.

## Scope

The change is limited to selected/origin station rendering in `SchematicMapPainter`. It does not redesign station labels, alter line placement, change map zoom behavior, or modify route-selection logic.

## Verification

- Add or update painter tests for selected, origin, and selected-plus-origin precedence.
- Verify regular coded nodes, nodes without codes, major hubs, and merged hubs.
- Run Flutter analysis and the relevant map/widget tests.
- Visually inspect the result on the Android emulator at normal and low zoom to confirm the node is clear without resembling a target.
