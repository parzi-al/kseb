# Tasks: Splash Screen & Smooth UI Transitions

**Input**: Design documents from `/specs/003-splash-smooth-ui/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: Included — spec requires XI. Test-Gated Development (constitution principle) and SC-008 mandates all 194+ existing tests continue to pass.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Project initialization — no code logic, just scaffolding

- [ ] T001 Create animation constants file at lib/utils/animation_constants.dart with all timing, curve, and scale constants from data-model.md Entity 1 (splashMinDuration, splashMaxDuration, splashIconScaleDuration, splashTextSlideDuration, splashCrossFadeDuration, pageTransitionDuration, pageTransitionCurve, pressScaleFactor, pressScaleDuration, pressScaleCurve, contentFadeInDuration, staggerDelayPerItem, staggerMaxIndex, staggerItemDuration, staggerSlideOffset, staggerCurve, appName)
- [ ] T002 [P] Export AnimationConstants from lib/utils/design_tokens.dart barrel file

**Checkpoint**: AnimationConstants available for all subsequent phases

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared animation infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 [P] Create reduce-motion helper function in lib/utils/animation_constants.dart — `Duration respectMotion(BuildContext context, Duration normal)` that returns Duration.zero when MediaQuery.disableAnimations is true (FR-015, research R3)
- [ ] T004 [P] Write unit tests for AnimationConstants values and respectMotion helper in test/utils/animation_constants_test.dart

**Checkpoint**: Foundation ready — animation constants and accessibility helper in place. User story implementation can begin.

---

## Phase 3: User Story 1 — Branded Splash Screen (Priority: P1) 🎯 MVP

**Goal**: Display a branded splash animation on every cold app launch — lightning bolt icon scales up, "KSEB" text slides up, then cross-fade to login/home screen.

**Independent Test**: Launch the app cold. Verify a branded animation plays (icon + text), then the correct screen (login or home) appears via cross-fade without jarring cut.

### Tests for User Story 1

- [ ] T005 [P] [US1] Write widget tests for SplashScreen in test/screens/splash_screen_test.dart — verify: (a) splash renders icon and "KSEB" text, (b) transitions to home/login after min duration, (c) reduce-motion shows static frame, (d) loading indicator appears if auth takes longer than max duration

### Implementation for User Story 1

- [ ] T006 [US1] Create SplashScreen widget in lib/screens/splash_screen.dart — StatefulWidget with AnimationController driving TweenSequence: icon scale-up (0→800ms), text slide-up (800→1300ms), hold to 1500ms min. Coordinate with Firebase auth via StreamBuilder/Future. Cross-fade (400ms) to LoginScreen or WorkerHomeScreen. Show pulsing indicator if auth exceeds 2500ms max. Respect reduce-motion (static frame + Duration.zero). Use AppColors.primary, AppColors.background, AppTypography.displayLargeStyle per design tokens (FR-001 through FR-006)
- [ ] T007 [US1] Integrate SplashScreen into lib/main.dart — replace `home: SafeArea(child: StreamBuilder<User?>(...))` with `home: const SplashScreen()`. Move auth StreamBuilder logic into SplashScreen's internal state management
- [ ] T008 [US1] Verify splash_screen_test.dart tests pass and all 194+ existing tests still pass

**Checkpoint**: User Story 1 complete — app launches with branded splash, then cross-fades to correct screen. MVP shippable.

---

## Phase 4: User Story 2 — Smooth Page Transitions (Priority: P2)

**Goal**: All screen-to-screen navigations use a consistent slide-from-right + fade animation instead of default Material transitions.

**Independent Test**: Navigate from home to any sub-screen and back. Verify smooth branded transition in both directions.

### Tests for User Story 2

- [ ] T009 [P] [US2] Write unit tests for AppPageTransition and AppRoute in test/utils/page_transitions_test.dart — verify: (a) AppRoute has correct transitionDuration, (b) AppPageTransition.buildTransitions returns SlideTransition+FadeTransition, (c) reduce-motion returns child directly, (d) reverse animation works

### Implementation for User Story 2

- [ ] T010 [US2] Create AppPageTransition (PageTransitionsBuilder) and AppRoute (MaterialPageRoute subclass) in lib/utils/page_transitions.dart — AppPageTransition.buildTransitions: SlideTransition Offset(1.0,0.0)→Offset.zero + FadeTransition 0.0→1.0 with easeOutCubic. AppRoute overrides transitionDuration to 300ms. Respect reduce-motion (return child directly). Export from lib/utils/page_transitions.dart (FR-007 through FR-011)
- [ ] T011 [US2] Register AppPageTransition in ThemeData inside lib/main.dart — add pageTransitionsTheme with AppPageTransition for all TargetPlatforms (android, iOS, windows, macOS, linux) in createAppTheme()
- [ ] T012 [US2] Migrate 6 MaterialPageRoute calls to AppRoute in lib/screens/worker_home_screen.dart (lines 637, 655, 671, 684, 697, 710)
- [ ] T013 [P] [US2] Migrate 1 MaterialPageRoute call to AppRoute in lib/screens/bonus_management_screen.dart (line 233)
- [ ] T014 [P] [US2] Migrate 2 MaterialPageRoute calls to AppRoute in lib/screens/material_management_screen.dart (lines 83, 99)
- [ ] T015 [US2] Verify page_transitions_test.dart tests pass and all existing tests still pass

**Checkpoint**: User Story 2 complete — all 9 navigation routes use branded slide+fade transitions globally.

---

## Phase 5: User Story 3 — Micro-Interaction Polish (Priority: P3)

**Goal**: Interactive elements feel tactile — dashboard cards scale on press, lists stagger in, loaded content fades in.

**Independent Test**: Tap any dashboard card and verify press-scale animation. Open a list screen and verify staggered entrance. Load data and verify content fades in.

### Tests for User Story 3

- [ ] T016 [P] [US3] Write widget tests for PressableScale in test/components/common/pressable_scale_test.dart — verify: (a) scales to 0.96 on tap down, (b) springs back on tap up, (c) forwards onTap callback, (d) reduce-motion disables scale, (e) enabled=false disables animation
- [ ] T017 [P] [US3] Write widget tests for StaggeredListItem in test/components/common/staggered_list_item_test.dart — verify: (a) applies stagger delay based on index, (b) fade+slide entrance plays, (c) reduce-motion shows instantly, (d) respects staggerMaxIndex cap
- [ ] T018 [P] [US3] Write widget tests for FadeInWidget in test/components/common/fade_in_widget_test.dart — verify: (a) child fades in over contentFadeInDuration, (b) custom duration override works, (c) reduce-motion shows instantly

### Implementation for User Story 3

- [ ] T019 [P] [US3] Create PressableScale widget in lib/components/common/pressable_scale.dart — StatefulWidget with AnimationController + GestureDetector (onTapDown/Up/Cancel). Transform.scale with easeOutBack spring curve. Respect reduce-motion. Props: child (required), onTap, scaleFactor (default 0.96), enabled (default true) (FR-012)
- [ ] T020 [P] [US3] Create StaggeredListItem widget in lib/components/common/staggered_list_item.dart — StatefulWidget with per-item AnimationController. Delay = min(index, 8) * 60ms. FadeTransition + SlideTransition (Offset(0, 0.08)→zero). Plays once per lifecycle. Respect reduce-motion (FR-014)
- [ ] T021 [P] [US3] Create FadeInWidget in lib/components/common/fade_in_widget.dart — StatefulWidget with AnimationController driving FadeTransition. Default 250ms. Respect reduce-motion. Props: child (required), duration (optional) (FR-013)
- [ ] T022 [US3] Wrap dashboard cards with PressableScale in lib/screens/worker_home_screen.dart — modify _buildDashboardCard method (line 728) to wrap the card content with PressableScale, forwarding the existing onTap callback (FR-012, 6 card usages)
- [ ] T023 [US3] Wrap primary ListView.builder items with StaggeredListItem in lib/screens/bonus_history_screen.dart (line 308) (FR-014)
- [ ] T024 [P] [US3] Wrap primary ListView.builder items with StaggeredListItem in lib/screens/staff_management_screen.dart (lines 328, 454) (FR-014)
- [ ] T025 [P] [US3] Wrap ListView.builder items with StaggeredListItem in lib/screens/components/attendance_history_list.dart (line 26) (FR-014)
- [ ] T026 [US3] Add FadeInWidget wrapping to content-heavy screens where data loads asynchronously — identify StreamBuilder/FutureBuilder result widgets and wrap with FadeInWidget (FR-013)
- [ ] T027 [US3] Verify all US3 widget tests pass and all existing tests still pass

**Checkpoint**: User Story 3 complete — all micro-interactions active: press-scale on 6 dashboard cards, staggered entrance on 4 list views, content fade-in on data-loaded screens.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, accessibility audit, and documentation

- [ ] T028 Run full test suite (`flutter test`) — verify all tests pass including new animation tests and all 194+ existing tests (SC-008)
- [ ] T029 Verify zero new hardcoded color or spacing values introduced — grep for hex codes and pixel values in new files, ensure all use AppColors/AppSpacing/AnimationConstants (SC-007, FR-016)
- [ ] T030 [P] Verify reduce-motion accessibility — confirm all 6 animation widgets (SplashScreen, AppPageTransition, AppRoute, PressableScale, StaggeredListItem, FadeInWidget) check MediaQuery.disableAnimations and degrade gracefully (SC-006, FR-015)
- [ ] T031 [P] Run quickstart.md validation — verify all code examples in specs/003-splash-smooth-ui/quickstart.md compile and work correctly with implemented widgets
- [ ] T032 Final commit and branch readiness check — ensure all tasks complete, no lint warnings, clean build

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (AnimationConstants must exist) — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 — independent of US2 and US3
- **User Story 2 (Phase 4)**: Depends on Phase 2 — independent of US1 and US3
- **User Story 3 (Phase 5)**: Depends on Phase 2 — independent of US1 and US2
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (Splash)**: Phase 2 → T005–T008. No dependency on US2/US3.
- **US2 (Page Transitions)**: Phase 2 → T009–T015. No dependency on US1/US3.
- **US3 (Micro-Interactions)**: Phase 2 → T016–T027. No dependency on US1/US2.

### Within Each User Story

- Tests written FIRST and verified to fail before implementation
- Widget creation before integration into existing screens
- Core widget before migration/wrapping of existing components
- All story tests pass before moving to next priority

### Parallel Opportunities

**Phase 1**: T001 then T002 (T002 depends on T001)

**Phase 2**: T003 and T004 can run in parallel [P]

**Phase 3 (US1)**: T005 (test) can start immediately, then T006→T007→T008 sequentially

**Phase 4 (US2)**: T009 (test) first, then T010→T011 sequentially, then T012+T013+T014 in parallel [P], then T015

**Phase 5 (US3)**: T016+T017+T018 all in parallel [P] (tests), then T019+T020+T021 all in parallel [P] (widgets), then T022→T023, T024+T025 in parallel [P], T026→T027

**Cross-story parallelism**: After Phase 2 completes, US1/US2/US3 can theoretically proceed in parallel if multiple agents/developers work simultaneously.

---

## Parallel Example: User Story 2

```bash
# Step 1: Write test (fails initially)
Task T009: "Write tests for AppPageTransition and AppRoute in test/utils/page_transitions_test.dart"

# Step 2: Create widgets
Task T010: "Create AppPageTransition and AppRoute in lib/utils/page_transitions.dart"

# Step 3: Global registration
Task T011: "Register AppPageTransition in ThemeData in lib/main.dart"

# Step 4: Migrate call sites (these 3 run in parallel — different files)
Task T012: "Migrate 6 MaterialPageRoute in lib/screens/worker_home_screen.dart"
Task T013: "Migrate 1 MaterialPageRoute in lib/screens/bonus_management_screen.dart"
Task T014: "Migrate 2 MaterialPageRoute in lib/screens/material_management_screen.dart"

# Step 5: Verify
Task T015: "Run tests and verify"
```

## Parallel Example: User Story 3

```bash
# Step 1: Write all tests in parallel (3 test files, no dependencies)
Task T016: "PressableScale tests in test/components/common/pressable_scale_test.dart"
Task T017: "StaggeredListItem tests in test/components/common/staggered_list_item_test.dart"
Task T018: "FadeInWidget tests in test/components/common/fade_in_widget_test.dart"

# Step 2: Create all widgets in parallel (3 source files, no dependencies)
Task T019: "PressableScale in lib/components/common/pressable_scale.dart"
Task T020: "StaggeredListItem in lib/components/common/staggered_list_item.dart"
Task T021: "FadeInWidget in lib/components/common/fade_in_widget.dart"

# Step 3: Integrate into existing screens
Task T022: "Wrap dashboard cards in worker_home_screen.dart"
Task T023: "Wrap list items in bonus_history_screen.dart"
Task T024: "Wrap list items in staff_management_screen.dart"  # parallel with T025
Task T025: "Wrap list items in attendance_history_list.dart"   # parallel with T024
Task T026: "Wrap loaded content with FadeInWidget"

# Step 4: Verify
Task T027: "Run all tests"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (AnimationConstants)
2. Complete Phase 2: Foundational (reduce-motion helper + tests)
3. Complete Phase 3: User Story 1 (SplashScreen)
4. **STOP and VALIDATE**: Launch app, verify branded splash plays and cross-fades to correct screen
5. Deploy/demo if ready — splash alone provides the biggest UX upgrade

### Incremental Delivery

1. Phase 1 + 2 → Foundation ready (AnimationConstants, accessibility)
2. Phase 3: US1 (Splash) → Test independently → MVP! 🎯
3. Phase 4: US2 (Page Transitions) → Test independently → All navigation feels polished
4. Phase 5: US3 (Micro-Interactions) → Test independently → Full "smooth UI" feel
5. Phase 6: Polish → Final validation → Branch ready for merge

Each story adds value without breaking previous stories.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Tests must fail before implementation (TDD per constitution XI)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- team_dialog ListView.builder (line 510) excluded per spec (nested dialog list)
- staff_management_screen has 2 ListView.builder sites — both are primary screen-level lists, both get StaggeredListItem
- All animation widgets must check `MediaQuery.of(context).disableAnimations` — this is verified in Phase 6 T030
