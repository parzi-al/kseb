# Tasks: Uniform UI Design System

**Input**: Design documents from `/specs/002-ui-design-system/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: Included — plan.md constitution check XI mandates test-gated development; widget tests required before screen migration.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- All file paths are relative to repository root

---

## Phase 1: Setup

**Purpose**: Project initialization and shared test infrastructure

- [x] T001 Create test helper with GoogleFonts config and shared theme builder in test/helpers/test_helpers.dart
- [x] T002 [P] Create barrel export file for design tokens in lib/utils/design_tokens.dart

---

## Phase 2: Foundational — Design Token System

**Purpose**: Extract and formalize the design token system from the existing `app_colors.dart` monolith. MUST complete before any widget or screen work.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Token File Creation

- [x] T003 [P] Create lib/utils/app_typography.dart with 8 named TextStyles, 8 font size constants, and TextTheme mapping per data-model.md
- [x] T004 [P] Create lib/utils/app_spacing.dart with 8 spacing values, 5 border radius constants, 4 shadow presets per data-model.md
- [x] T005 [P] Create lib/utils/app_decorations.dart with card decoration presets, gradient definitions, and responsive BuildContext extensions per data-model.md and research.md R-003

### Token Refactoring

- [x] T006 Refactor lib/utils/app_colors.dart to contain only color tokens — remove typography, spacing, decorations, and responsive helpers that moved to T003–T005
- [x] T007 Update lib/utils/design_tokens.dart barrel export to re-export all 4 token files

### Theme Configuration

- [x] T008 Update lib/main.dart root ThemeData with manual ColorScheme, AppBarTheme, CardTheme, InputDecorationTheme, ElevatedButtonTheme, TextButtonTheme, and FloatingActionButtonTheme per contracts/theme-contract.md
- [x] T009 Update all existing import statements across lib/ to reference new token file locations (app_typography, app_spacing, app_decorations instead of app_colors for non-color members)

### Token Verification Tests

- [x] T010 [P] Create test/utils/app_colors_test.dart — verify all color token values match data-model.md hex values
- [x] T011 [P] Create test/utils/app_typography_test.dart — verify TextStyle properties (fontSize, fontWeight, fontFamily) match data-model.md
- [x] T012 [P] Create test/utils/app_spacing_test.dart — verify spacing, radius, and elevation constant values match data-model.md
- [x] T013 Verify all existing tests pass after token system refactor (run full test suite)

**Checkpoint**: Token system complete — 4 focused modules, root theme configured, all tests green. Widget and screen work can now begin.

---

## Phase 3: User Story 2 — Reusable Widget Library (Priority: P1) 🎯 MVP

**Goal**: Build a shared library of 8 pre-built widgets so developers never write inline styling and every new screen automatically matches the design system.

**Independent Test**: A developer can build a new screen using only the shared widget library and design tokens — no inline `TextStyle`, `BoxDecoration`, `EdgeInsets`, or raw `Colors.*` needed.

### Widget Tests (write FIRST — must FAIL before implementation)

- [x] T014 [P] [US2] Create test/components/common/app_bar_builder_test.dart — verify AppBar properties (backgroundColor, foregroundColor, elevation, titleTextStyle) match contract
- [x] T015 [P] [US2] Create test/components/common/app_card_test.dart — verify default decoration, accent variant border, onTap InkWell, padding override
- [x] T016 [P] [US2] Create test/components/common/app_button_test.dart — verify all 4 variants (primary/outline/destructive/text), isLoading spinner, disabled opacity, icon placement
- [x] T017 [P] [US2] Create test/components/common/app_text_field_test.dart — verify border, focus color, label style, error display
- [x] T018 [P] [US2] Create test/components/common/app_loading_test.dart — verify 3 variants (fullPage/inline/overlay), spinner color, message display
- [x] T019 [P] [US2] Create test/components/common/app_empty_state_test.dart — verify icon, title, subtitle, action button rendering
- [x] T020 [P] [US2] Create test/components/common/app_error_state_test.dart — verify error icon, message, retry button
- [x] T021 [P] [US2] Create test/components/common/app_scaffold_test.dart — verify default padding, scrollable behavior, background color

### Widget Implementation

- [x] T022 [P] [US2] Implement AppBarBuilder in lib/components/common/app_bar_builder.dart per contracts/widget-library.md
- [x] T023 [P] [US2] Implement AppCard in lib/components/common/app_card.dart per contracts/widget-library.md
- [x] T024 [P] [US2] Implement AppButton with AppButtonVariant enum in lib/components/common/app_button.dart per contracts/widget-library.md
- [x] T025 [P] [US2] Implement AppTextField in lib/components/common/app_text_field.dart per contracts/widget-library.md
- [x] T026 [P] [US2] Implement AppLoading with AppLoadingVariant enum in lib/components/common/app_loading.dart per contracts/widget-library.md
- [x] T027 [P] [US2] Implement AppEmptyState in lib/components/common/app_empty_state.dart per contracts/widget-library.md
- [x] T028 [P] [US2] Implement AppErrorState in lib/components/common/app_error_state.dart per contracts/widget-library.md
- [x] T029 [P] [US2] Implement AppPageWrapper in lib/components/common/app_scaffold.dart per contracts/widget-library.md

### Existing Component Update

- [x] T030 [US2] Update lib/components/common/modern_dropdown.dart to use design tokens (AppColors, AppTypography, AppSpacing) instead of inline styling
- [x] T031 [US2] Run all widget tests and verify they pass (T014–T021)

**Checkpoint**: Widget library complete — all 8 shared widgets implemented, all widget tests green. Screen migration can now begin.

---

## Phase 4: User Story 1 — Consistent Visual Identity Across All Screens (Priority: P1)

**Goal**: Migrate all screens to use design tokens and shared widgets, converging on the homepage visual standard — same colors, typography, spacing, card layouts, and button styles everywhere.

**Independent Test**: Navigate through every screen (Home → Attendance → Staff Management → Worksheet → Material Management → Bonus Management → Login) and verify colors, fonts, card shapes, button styles, and spacing are visually uniform.

**Migration per screen**: Replace inline colors with AppColors tokens, inline TextStyles with AppTypography tokens, magic-number spacing with AppSpacing tokens, custom card decorations with AppCard, custom buttons with AppButton, custom text fields with AppTextField, custom AppBars with buildAppBar(), body wrappers with AppPageWrapper. Apply responsive helpers via BuildContext extensions. Replace `Color.withOpacity()` with `Color.withValues(alpha:)` per FR-018.

### Screen Migration (simplest → most complex per research.md R-010)

- [x] T032 [US1] Migrate lib/screens/attendance_history_screen.dart (88 lines) to design system
- [x] T033 [US1] Migrate lib/screens/material_management_screen.dart (214 lines) to design system
- [x] T034 [US1] Migrate lib/screens/login_screen.dart (302 lines) to design system
- [x] T035 [US1] Migrate lib/screens/attendance_screen.dart (485 lines) to design system
- [x] T036 [US1] Migrate lib/screens/components/attendance_calendar.dart to design system
- [x] T037 [US1] Migrate lib/screens/components/attendance_stats_card.dart to design system
- [x] T038 [US1] Migrate lib/screens/components/attendance_history_list.dart to design system
- [x] T039 [US1] Migrate lib/screens/add_material_screen.dart (588 lines) to design system
- [x] T040 [US1] Migrate lib/screens/bonus_history_screen.dart (597 lines) to design system
- [x] T041 [US1] Migrate lib/screens/bonus_management_screen.dart (706 lines) to design system
- [x] T042 [US1] Migrate lib/screens/withdraw_material_screen.dart (770 lines) — remove DatePicker Theme() workaround per research.md R-001
- [x] T043 [US1] Migrate lib/screens/staff_management_screen.dart (828 lines) to design system
- [x] T044 [P] [US1] Migrate lib/components/staff/staff_card.dart — replace raw Colors.* with tokens
- [x] T045 [P] [US1] Migrate lib/components/staff/staff_form_dialog.dart to design system
- [x] T046 [P] [US1] Migrate lib/components/staff/add_staff_dialog.dart to design system
- [x] T047 [P] [US1] Migrate lib/components/staff/edit_staff_dialog.dart to design system
- [x] T048 [P] [US1] Migrate lib/components/staff/delete_staff_dialog.dart to design system
- [x] T049 [P] [US1] Migrate lib/components/staff/staff_details_bottom_sheet.dart to design system
- [x] T050 [US1] Migrate lib/components/team/team_dialog.dart to design system
- [x] T051 [US1] Migrate lib/screens/worksheet_screen.dart (829 lines) to design system
- [x] T052 [US1] Validate lib/screens/worker_home_screen.dart (861 lines) against design tokens — this is the reference standard; update only to use token references instead of literals where needed
- [x] T053 [US1] Run full test suite and verify no regressions after screen migration

**Checkpoint**: All screens visually converge on the homepage standard. User Story 1 is complete and independently testable.

---

## Phase 5: User Story 3 — Consistent Loading and Error Feedback (Priority: P2)

**Goal**: Every screen uses the same loading animation, error presentation, and empty-state display so users always know what the app is doing and how to recover.

**Independent Test**: Trigger loading states and error conditions on each screen and verify the visual treatment is identical everywhere.

### Loading/Error/Empty State Audit & Implementation

- [x] T054 [US3] Audit all screens for existing loading implementations — document which screens use custom spinners vs. no loading state
- [x] T055 [US3] Replace all custom loading indicators with AppLoading across all screen files
- [x] T056 [US3] Add AppErrorState to screens that handle errors with raw Text/Container instead of the shared widget
- [x] T057 [US3] Add AppEmptyState to list/data screens that lack empty-state handling (material management, bonus history, worksheet)
- [x] T058 [US3] Verify TableCalendar loading and error states in lib/screens/attendance_screen.dart and lib/screens/components/attendance_calendar.dart use AppLoading and AppErrorState per research.md R-007

**Checkpoint**: Loading, error, and empty states are visually consistent across all screens. User Story 3 is complete.

---

## Phase 6: User Story 4 — Responsive Spacing on All Screens (Priority: P2)

**Goal**: Every screen uses responsive helpers so spacing, font sizes, and touch targets scale properly across phone and tablet sizes.

**Independent Test**: Run the app on 360dp, 400dp, and 600dp+ width and verify spacing/fonts scale appropriately on every screen.

### Responsive Migration

- [x] T059 [US4] Audit all screens for responsive helper usage — document which screens use vs. skip responsive scaling
- [x] T060 [US4] Apply BuildContext responsive extensions (responsivePadding, responsiveSpacing, responsiveFontSize) to all screen files that lack them
- [x] T061 [US4] Verify AppPageWrapper responsive padding works correctly across breakpoints in all screens
- [x] T062 [US4] Verify touch targets (buttons, card taps, list items) meet minimum 48dp on smallest supported screen width (360dp)

**Checkpoint**: All screens scale responsively. User Story 4 is complete.

---

## Phase 7: User Story 5 — Elimination of Inline Styling (Priority: P3)

**Goal**: Zero inline `TextStyle` constructors, zero inline `BoxDecoration` for cards, zero raw `Colors.*`, zero magic-number `SizedBox` spacing in any screen file for standardized elements.

**Independent Test**: Run a grep audit of all screen and component files and confirm no inline styling exists for standardized elements.

### Final Audit & Cleanup

- [x] T063 [US5] Grep audit all lib/screens/ and lib/components/ files for raw `Colors.` references — replace with AppColors tokens
- [x] T064 [US5] Grep audit all lib/screens/ and lib/components/ files for inline `TextStyle(` constructors — replace with AppTypography tokens
- [x] T065 [US5] Grep audit all lib/screens/ and lib/components/ files for magic-number `SizedBox(height:` and `SizedBox(width:` — replace with AppSpacing tokens
- [x] T066 [US5] Grep audit all lib/screens/ and lib/components/ files for `Color.withOpacity(` — replace with `Color.withValues(alpha:)` per FR-018
- [x] T067 [US5] Add `// DS-EXCEPTION:` comments for any legitimate one-off values that cannot use tokens (per quickstart.md escape hatch pattern)
- [x] T068 [US5] Run full test suite and verify no regressions after cleanup pass

**Checkpoint**: All inline styling eliminated. Codebase passes static audit. User Story 5 is complete.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, documentation, and cleanup across all user stories

- [ ] T069 [P] Remove lib/screens/staff_management_screen.dart.new (stale file in repository)
- [ ] T070 Run quickstart.md validation — build a minimal test screen using only shared widgets and tokens, confirm zero inline styling needed
- [ ] T071 Verify all success criteria SC-001 through SC-010 from spec.md are met
- [ ] T072 Update README.md with design system usage reference (link to quickstart.md)
- [ ] T073 Run full test suite — all tests must pass (token tests, widget tests, existing tests)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **BLOCKS all user stories**
- **US2 Widget Library (Phase 3)**: Depends on Phase 2 — **BLOCKS screen migration (Phase 4)**
- **US1 Screen Migration (Phase 4)**: Depends on Phase 2 + Phase 3
- **US3 Loading/Error (Phase 5)**: Depends on Phase 3 (widgets) + Phase 4 (screens migrated)
- **US4 Responsive (Phase 6)**: Depends on Phase 2 (tokens) + Phase 4 (screens migrated)
- **US5 Inline Audit (Phase 7)**: Depends on Phases 4, 5, 6 (all migration complete)
- **Polish (Phase 8)**: Depends on all prior phases

### User Story Dependencies

- **US2 (P1)**: Depends on Foundational only — can start as soon as tokens exist
- **US1 (P1)**: Depends on Foundational + US2 — needs tokens AND widgets before migrating screens
- **US3 (P2)**: Depends on US2 (widgets exist) + US1 (screens migrated so loading/error can be audited)
- **US4 (P2)**: Depends on US1 (screens migrated so responsive can be applied uniformly)
- **US5 (P3)**: Depends on US1 + US3 + US4 — final audit after all other migration is done

### Within Each User Story

- Tests MUST be written and FAIL before widget implementation (US2)
- Token files before theme configuration (Phase 2)
- Widgets before screen migration (FR-019)
- Simplest screens first → complex screens last (R-010)
- Each screen is a single verifiable step (FR-019)
- Commit after each task or logical group

### Parallel Opportunities

- **Phase 1**: T001 and T002 can run in parallel
- **Phase 2**: T003, T004, T005 can run in parallel (different files). T010, T011, T012 can run in parallel.
- **Phase 3**: All widget tests (T014–T021) can run in parallel. All widget implementations (T022–T029) can run in parallel.
- **Phase 4**: Staff component migrations (T044–T049) can run in parallel. Other screen migrations are sequential (shared file changes).
- **Phase 7**: All grep audits (T063–T066) can run in parallel.

---

## Parallel Example: User Story 2 (Widget Library)

```text
# Batch 1: Launch all widget tests in parallel
T014: test/components/common/app_bar_builder_test.dart
T015: test/components/common/app_card_test.dart
T016: test/components/common/app_button_test.dart
T017: test/components/common/app_text_field_test.dart
T018: test/components/common/app_loading_test.dart
T019: test/components/common/app_empty_state_test.dart
T020: test/components/common/app_error_state_test.dart
T021: test/components/common/app_scaffold_test.dart

# Batch 2: Launch all widget implementations in parallel
T022: lib/components/common/app_bar_builder.dart
T023: lib/components/common/app_card.dart
T024: lib/components/common/app_button.dart
T025: lib/components/common/app_text_field.dart
T026: lib/components/common/app_loading.dart
T027: lib/components/common/app_empty_state.dart
T028: lib/components/common/app_error_state.dart
T029: lib/components/common/app_scaffold.dart

# Batch 3: Sequential finalization
T030: modern_dropdown.dart update
T031: Run all widget tests → all green
```

---

## Parallel Example: Phase 2 (Token System)

```text
# Batch 1: Create all new token files in parallel
T003: lib/utils/app_typography.dart
T004: lib/utils/app_spacing.dart
T005: lib/utils/app_decorations.dart

# Batch 2: Sequential (depends on Batch 1)
T006: Refactor app_colors.dart (remove extracted content)
T007: Update barrel export

# Batch 3: Theme + imports (sequential)
T008: Update main.dart ThemeData
T009: Fix imports across codebase

# Batch 4: Token tests in parallel
T010: test/utils/app_colors_test.dart
T011: test/utils/app_typography_test.dart
T012: test/utils/app_spacing_test.dart

# Batch 5: Verify
T013: Run full test suite
```

---

## Implementation Strategy

### MVP First (Phase 1 + Phase 2 + US2 + first 3 screens of US1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational token system + theme
3. Complete Phase 3: US2 widget library
4. Migrate first 3 screens of US1 (attendance_history, material_management, login)
5. **STOP and VALIDATE**: Visual consistency on migrated screens, all tests green
6. This is a usable MVP — design system exists, key screens are migrated

### Incremental Delivery

1. Setup + Foundational → Token system live, theme updated
2. US2 Widget Library → Shared widgets available for use
3. US1 Screen Migration → Visual consistency across all screens (biggest batch)
4. US3 Loading/Error → Consistent feedback states
5. US4 Responsive → All screens scale correctly
6. US5 Inline Audit → Code quality enforcement
7. Polish → Documentation and final validation
8. Each story adds value without breaking previous stories

### Suggested MVP Scope

**US2 (Widget Library) alone** is a valid MVP — it delivers the tooling that prevents future drift. Pair it with 2–3 screen migrations from US1 for visible impact.

---

## Summary

| Metric | Count |
|--------|-------|
| **Total tasks** | 73 |
| **Phase 1 (Setup)** | 2 |
| **Phase 2 (Foundational)** | 11 |
| **Phase 3 / US2 (Widget Library)** | 18 |
| **Phase 4 / US1 (Screen Migration)** | 22 |
| **Phase 5 / US3 (Loading/Error)** | 5 |
| **Phase 6 / US4 (Responsive)** | 4 |
| **Phase 7 / US5 (Inline Audit)** | 6 |
| **Phase 8 (Polish)** | 5 |
| **Parallelizable tasks** | 34 |
| **Test tasks** | 14 |

### Independent Test Criteria per Story

| Story | Independent Test |
|-------|-----------------|
| US1 | Navigate all screens — visual identity matches homepage standard |
| US2 | Build a new screen using only shared widgets and tokens — zero inline styling |
| US3 | Trigger loading/error/empty on every screen — identical visual treatment |
| US4 | Run on 360dp/400dp/600dp+ — spacing and fonts scale on every screen |
| US5 | Grep audit lib/ — zero raw Colors.*, inline TextStyle, magic SizedBox |

### Format Validation

✅ All 73 tasks follow the checklist format: `- [ ] [TaskID] [P?] [Story?] Description with file path`  
✅ All user story phase tasks include [US*] labels  
✅ Setup and Foundational phase tasks have no story labels  
✅ Polish phase tasks have no story labels  
✅ Task IDs are sequential (T001–T073)
