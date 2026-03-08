# Research: Uniform UI Design System

**Feature**: `002-ui-design-system` | **Date**: 2026-03-08

## R-001: ThemeData & ColorScheme Migration

**Decision**: Use manual `ColorScheme()` constructor populated from `AppColors` values — NOT `ColorScheme.fromSeed()`.

**Rationale**: The app has a prescribed multi-color brand palette (orange primary, purple secondary, teal accent, enumerated greys) that was deliberately chosen, not derived from a single seed. `fromSeed()` would algorithmically replace the purple secondary with an orange-adjacent hue, breaking the existing design.

**Alternatives considered**:
- `ColorScheme.fromSeed(seedColor: Color(0xFFFF6B35))` — rejected because generated tones don't match the existing palette.
- Hybrid `fromSeed().copyWith()` — rejected because auto-generated tones bleed through in unexpected roles (e.g., `surfaceTint`, `outlineVariant`).

**Integration pattern**: Define `AppColors` as the single source of truth. Build `ColorScheme` from `AppColors` values in one factory function. Never duplicate hex values between `AppColors` and `ColorScheme`. Set component themes (`AppBarTheme`, `ElevatedButtonTheme`, `CardTheme`, `InputDecorationTheme`) that reference `colorScheme` roles so framework widgets inherit automatically.

**Current pain point confirmed**: `withdraw_material_screen.dart` already wraps `DatePicker` with a manual `Theme(data: ...)` override to force orange on the teal-themed picker. This workaround disappears once `ColorScheme.primary` is set correctly.

---

## R-002: Design Token Architecture

**Decision**: `abstract final class` with `static const` fields, split across 4 files, barrel-exported via a single `design_tokens.dart`.

**Rationale**: App is light-mode-only (spec A-004); `abstract final class` (Dart 3.0+) prevents instantiation, tree-shakes well, and provides clear namespaces with IDE autocomplete. When dark mode is needed later, each class becomes the light implementation behind an interface served via `InheritedWidget` — minimal refactor.

**Alternatives considered**:
- Extension methods on `BuildContext` — more boilerplate, harder to use in non-widget code, unfamiliar to junior devs.
- `InheritedWidget` token provider — heavy ceremony for a light-mode-only app, overkill without dark mode.

**File layout**:
```
lib/utils/
  app_colors.dart           # Color tokens only (~50 lines)
  app_typography.dart       # TextStyle tokens only (~60 lines)
  app_spacing.dart          # Spacing, radius, elevation constants (~40 lines)
  app_decorations.dart      # BoxDecoration presets, responsive helpers (~80 lines)
```

**Typography**: Feed tokens into `ThemeData.textTheme` so framework widgets (`ListTile`, `AppBar`, `AlertDialog`) auto-inherit correct styles. Also keep semantic named getters (`AppTypography.heading`, `AppTypography.caption`) for direct use in screen code — both point to the same `TextStyle` objects.

---

## R-003: Responsive Scaling Helpers

**Decision**: Migrate from static methods on `AppColors` to `BuildContext` extensions in `app_decorations.dart`.

**Rationale**: Extensions on `BuildContext` are the community-standard pattern (used by `Theme.of(context)`, `MediaQuery.of(context)`, and packages like `flutter_screenutil`). They eliminate the positional `context` parameter and read naturally: `context.responsivePadding(16)` instead of `AppColors.getResponsivePadding(context, 16)`.

**Alternatives considered**:
- Keep as static methods — works but verbose, wrong namespace (color class has responsive methods).
- Standalone functions — lose namespace discoverability.

**Scaling algorithm**: Unchanged. The existing 3-tier breakpoint system (`<700`, `<800`, `≥800` screen height) and linear scaling against iPhone 14 baseline (844×390) are preserved. Only the calling convention changes.

---

## R-004: Reusable Button Widget

**Decision**: Single `AppButton` widget with `AppButtonVariant` enum (`primary`, `outline`, `destructive`, `text`).

**Rationale**: The variants share 90% of their API (label, onPressed, isLoading, isDisabled, icon, fullWidth). Only visual treatment differs. A single class with an internal `switch` on the variant enum is forward-compatible — adding a new variant means an enum case and its decoration, not a new file.

**Alternatives considered**:
- Separate classes (`GradientButton`, `OutlineButton`, etc.) — duplicated loading/disabled logic, more imports, divergence risk.

---

## R-005: Reusable Card Widget

**Decision**: Hybrid approach — set `CardTheme` in `ThemeData` so vanilla `Card()` looks correct everywhere, then provide an `AppCard` widget only for the variant with a colored border or accent.

**Rationale**: Most card usage in the app is straightforward (white background, standard shadow, 16px radius). Framework's `Card` already handles this with the right `CardTheme`. The custom `AppCard` is only needed for the colored-border variant used in dashboard cards. This avoids creating an unnecessary wrapper for the common case.

**Alternatives considered**:
- Custom `Container` wrapper for all cards — bypasses framework `Card` semantics (InkWell, elevation, theme inheritance).
- Only `CardTheme`, no custom widget — can't handle the colored-border variant that exists on the homepage dashboard.

---

## R-006: Page Scaffold Widget

**Decision**: `AppPageWrapper` widget that goes inside `Scaffold.body` — not a `Scaffold` replacement.

**Rationale**: Flutter team explicitly advises against extending `Scaffold`. `AppPageWrapper` provides standard page padding (via responsive tokens), background color, and optional `SingleChildScrollView` wrapping. Screens keep control of `Scaffold` properties (`appBar`, `floatingActionButton`, `bottomNavigationBar`).

**Alternatives considered**:
- Custom `AppScaffold` extending `Scaffold` — fragile, signature duplication, breaks across Flutter versions.
- Function that returns configured `Scaffold` — no widget lifecycle, can't be `const`.

---

## R-007: TableCalendar Theming

**Decision**: Keep `CalendarBuilders` for custom cell rendering (complex holiday/attendance/weekend state overlap). Apply design tokens to `CalendarStyle`, `HeaderStyle`, and `DaysOfWeekStyle` for parts that remain default. Create a factory method (e.g., `AppCalendarStyles.calendarStyle()`) that builds these from tokens.

**Rationale**: `table_calendar 3.1.2` accepts standard Flutter types (`BoxDecoration`, `TextStyle`) for all style properties. Cell rendering is already custom-built via `CalendarBuilders` — this stays because the complex state overlap (present/absent/holiday/weekend) requires custom logic. But header and weekday rows can simply inherit from tokens.

**Limitations**:
- Row height / cell sizing are constructor parameters, not style properties (easy to miss).
- Internal `TableRow`/`TableCell` padding is not customizable via style objects — `CalendarBuilders` is needed for custom inter-cell spacing.
- Header layout structure (title between two chevrons) is fixed — only content/style is customizable.

---

## R-008: Testing Strategy

**Decision**: Use `tester.widget<T>()` property inspection as the primary testing strategy. Defer golden tests.

**Rationale**: For verifying "button has borderRadius 16, backgroundColor AppColors.primary" — property inspection is deterministic, fast (~ms), platform-independent, and CI-friendly. Golden tests introduce platform-dependent rendering differences, golden file maintenance, and regeneration ceremonies. Start with structural tests; add golden tests later if visual regression becomes a problem.

**GoogleFonts in tests**: Set `GoogleFonts.config.allowRuntimeFetching = false` in `setUpAll()` to prevent HTTP calls in the test environment. Font-metric matching is not needed for property-inspection tests (which check `fontFamily` string, `fontSize` value, etc., not rendered pixels).

**Test scope per widget**: Verify that each widget's key visual properties (color, borderRadius, padding, textStyle) match the expected design token values. Verify variant behavior (e.g., AppButton.primary vs .destructive). Verify loading/disabled states render correctly.

---

## R-009: AppBar Builder Pattern

**Decision**: Provide an `AppBarBuilder` function/widget that returns a pre-configured `AppBar` with standard values (surface background, text-primary foreground, 0.5 elevation, centered title, transparent surfaceTint). Also set `AppBarTheme` in `ThemeData` so even bare `AppBar()` inherits correct styling.

**Rationale**: The 5-property AppBar pattern is copy-pasted across 6+ screens currently. A builder centralizes this. But since `AppBarTheme` exists in Flutter's theme system, the right approach is dual: set the theme defaults AND provide a builder for screens that need actions or custom titles. Most screens can then use `AppBar(title: Text('...'))` and inherit everything from the theme.

---

## R-010: Migration Order

**Decision**: Foundation first (tokens → theme → widgets), then screens incrementally in order of complexity (simplest first).

**Rationale**: Per spec FR-019, the design token system and widget library must be complete before screen migration begins. Migrating simplest screens first builds confidence and catches widget API issues early, before tackling the 800+ line screens.

**Suggested order**:
1. Token files (app_colors narrowed, app_typography, app_spacing, app_decorations)
2. Root theme update (main.dart)
3. Shared widgets (app_card, app_button, app_text_field, app_loading, app_empty_state, app_error_state, app_scaffold, app_bar_builder)
4. Screen migration (simplest → most complex):
   - attendance_history_screen (88 lines)
   - material_management_screen (214 lines)
   - login_screen (302 lines)
   - attendance_screen + components (485 + 613 lines)
   - add_material_screen (588 lines)
   - bonus_history_screen (597 lines)
   - bonus_management_screen (706 lines)
   - withdraw_material_screen (770 lines)
   - staff_management_screen + components (828 + 2,215 lines)
   - worksheet_screen (829 lines)
   - worker_home_screen (861 lines — last, since it's the reference standard)
