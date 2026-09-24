# Line Filter Only Design

## Goal

Simplify the home map drawer so users filter the schematic map only by transit line. The unused area filter must no longer appear.

## User experience

- Opening the home filter drawer shows **Filter Jalur Transportasi** as the first and only filter section.
- The line section remains expanded by default.
- Existing KRL, MRT, LRT Jabodebek, and LRT Jakarta options keep their current behavior, colors, spacing, scrolling, and accessibility.
- The area heading, Greater Jakarta selection, city options, divider below the area section, and area “coming soon” notice are removed from this drawer.

## Implementation

- Delete the area `ExpansionTile` and its adjacent divider from `home_page.dart`.
- Delete the now-unused `_showAreaComingSoon` helper.
- Keep localization keys for now to avoid an unrelated generated-localization cleanup.
- Update widget tests to assert that the area filter is absent while the line filter remains present.
- Replace the obsolete area-notice test with a drawer contract test for the line-only layout.

## Verification

- Run the focused home filter and home widget tests.
- Run Flutter analysis.
- Run the full Flutter test suite before completion.

## Out of scope

- Redesigning individual line options.
- Changing map filtering logic.
- Removing localization keys across all supported languages.
