# Feature Specification: Splash Screen & Smooth UI Transitions

**Feature Branch**: `003-splash-smooth-ui`
**Created**: 2026-03-09
**Status**: Draft
**Input**: User description: "define the splash screen spec for the app and make app ui fully fluid and smooth"

## Clarifications

### Session 2026-03-09

- Q: What specific splash animation visual design should be used? → A: Lightning bolt icon scales up from center with fade-in, followed by "KSEB" text sliding up beneath it (clean, minimal, no external assets), but keep the text in the common config file for easy changes.
- Q: What slide direction for page transitions? → A: Slide from right + fade (standard mobile forward-navigation convention).
- Q: Which lists get staggered entrance animations? → A: Only primary screen-level lists (staff, materials, bonus history, worksheets), not nested sub-lists or dropdowns.
- Q: What transition style from splash to main screen? → A: Cross-fade (splash fades out while destination fades in simultaneously, distinct from regular page transitions).

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Branded Splash Screen on App Launch (Priority: P1)

When a user opens the KSEB app, they see a polished, branded splash animation featuring the app logo/icon and name. The animation plays for a short fixed duration, then seamlessly transitions to the authentication check (login screen or home screen). The splash replaces the current plain loading spinner shown during Firebase auth initialization.

**Why this priority**: The splash screen is the very first impression of the app. A professional opening animation immediately communicates quality and brand identity, replacing the current generic spinner.

**Independent Test**: Launch the app cold. Verify that a branded animation plays, then the correct screen (login or home) appears without a jarring cut.

**Acceptance Scenarios**:

1. **Given** the app is not running, **When** the user taps the app icon, **Then** a branded splash animation begins within 0.5 seconds of launch.
2. **Given** the splash animation is playing, **When** it completes (≤ 2.5 seconds), **Then** the app transitions smoothly to the login screen (if unauthenticated) or home screen (if authenticated).
3. **Given** the user is on a slow network, **When** Firebase initialization takes longer than the splash duration, **Then** the splash holds with a subtle loading indicator until initialization completes, then transitions.
4. **Given** the app is launched, **When** the splash plays, **Then** the animation uses the brand primary color (#FF6B35) and app name "KSEB" with consistent design-token styling.

---

### User Story 2 — Smooth Page Transitions Between Screens (Priority: P2)

When a user navigates between screens (e.g., home → attendance, home → materials, home → worksheets), the transition is a fluid animation instead of the default abrupt Material page push. All `Navigator.push` calls use a consistent, branded transition pattern.

**Why this priority**: Fluid page transitions are the single biggest contributor to the perception of a "smooth" app. Every screen-to-screen navigation (6+ routes) currently uses the default `MaterialPageRoute` which feels mechanical.

**Independent Test**: Navigate from the home screen to any sub-screen and back. Verify a smooth, branded transition animation plays in both directions.

**Acceptance Scenarios**:

1. **Given** the user is on the home screen, **When** they tap any navigation card (Attendance, Worksheet, Materials, Staff, Bonus), **Then** the destination screen enters with a smooth fade+slide animation.
2. **Given** the user is on a sub-screen, **When** they tap the back button or swipe back, **Then** the reverse transition plays smoothly.
3. **Given** any screen in the app uses `Navigator.push`, **When** the navigation occurs, **Then** the custom transition is applied consistently (no mix of default and custom transitions).
4. **Given** the app theme is configured, **When** any navigation occurs, **Then** the branded transition is applied automatically without per-route configuration.

---

### User Story 3 — Micro-Interaction Polish on Interactive Elements (Priority: P3)

Interactive elements across the app (buttons, cards, list items) respond to user touches with subtle feedback animations — press scale, ripple effects, and loading state transitions. This makes every tap feel responsive and intentional.

**Why this priority**: Micro-interactions polish the "feel" of the app after the splash and transitions are in place. They are additive — each one is small but collectively they make the UI feel alive.

**Independent Test**: Tap any dashboard card or button. Verify a tactile feedback animation (scale/ripple) plays on press.

**Acceptance Scenarios**:

1. **Given** the user sees a dashboard action card, **When** they press it, **Then** the card scales down subtly (e.g., 0.96×) and springs back on release.
2. **Given** the user taps a primary button, **When** the press begins, **Then** a ripple effect plays and the button responds within one frame.
3. **Given** a screen is loading data, **When** loading completes, **Then** content fades in rather than appearing instantly.
4. **Given** any list of items is displayed, **When** the list first renders, **Then** items animate in with a staggered entrance (slight delay between each item).

---

### Edge Cases

- What happens if the user kills the app mid-splash? — No state corruption; next launch restarts the splash cleanly.
- What happens if Firebase auth check returns instantly (cached session)? — Splash still plays its minimum duration for brand consistency, then transitions.
- What happens on very low-end devices? — Animations degrade gracefully; if frame rate drops below threshold, reduce animation complexity (fewer particles/effects) or skip to static frame.
- What happens if the user rapidly taps multiple navigation cards? — Only the first navigation is processed; subsequent taps during a transition are ignored.
- What happens on first-ever app launch vs. subsequent launches? — Same splash experience both times. No differentiation needed.

## Requirements *(mandatory)*

### Functional Requirements

**Splash Screen (US1)**

- **FR-001**: System MUST display a branded splash screen on every app launch before any other screen is shown.
- **FR-002**: The splash MUST feature the KSEB brand identity — primary color (#FF6B35), a lightning bolt icon that scales up from center with a fade-in, followed by the "KSEB" app name text sliding up beneath it.
- **FR-003**: The splash animation MUST have a minimum duration of 1.5 seconds and a maximum of 2.5 seconds under normal conditions.
- **FR-004**: If the authentication/initialization check completes before the splash minimum duration, the splash MUST continue to its minimum duration before transitioning.
- **FR-005**: If the authentication/initialization check takes longer than the splash maximum duration, the splash MUST display a subtle loading indicator (e.g., pulsing dot, progress shimmer) until ready.
- **FR-006**: The transition from splash to the next screen (login or home) MUST be a cross-fade — the splash fades out while the destination screen fades in simultaneously. This is distinct from the slide-from-right used for regular page navigation.

**Page Transitions (US2)**

- **FR-007**: All screen-to-screen navigations MUST use a custom branded transition instead of the platform default page transition.
- **FR-008**: The page transition MUST be a slide-from-right + fade combination with a duration between 250ms and 400ms. The incoming screen slides in from the right edge while fading in; back navigation reverses the direction (slides out to the right).
- **FR-009**: The transition MUST be reversible — back navigation plays the reverse animation.
- **FR-010**: The custom transition MUST be defined globally so any new screens added in the future automatically inherit the app's transition style.
- **FR-011**: The transition MUST not block user interaction after completing — no lingering overlays or dead zones.

**Micro-Interactions (US3)**

- **FR-012**: Dashboard action cards MUST have a press-scale animation (scale to ~0.96× on press, spring back on release).
- **FR-013**: Content-heavy screens MUST fade in their content when data loads, rather than appearing instantly (fade duration 200–300ms).
- **FR-014**: Primary screen-level list views (staff list, material list, bonus history, worksheet list) MUST stagger item entrance animations when the list first loads (50–100ms delay between items). Nested sub-lists, dropdowns, and dialog lists are excluded.
- **FR-015**: All animations MUST respect the device's "reduce motion" accessibility setting — if enabled, skip or minimize animations.
- **FR-016**: Animations MUST use the app's existing design tokens and avoid introducing new hardcoded color or spacing values.

### Key Entities

- **Splash Screen**: A full-screen widget displayed once on launch; holds brand visuals, coordinates timing with auth initialization, then transitions out.
- **Page Transition**: A reusable route transition definition applied globally or per-route; controls how screens enter and exit.
- **Animated Card/List Item**: A wrapper widget that adds press-scale or staggered-entrance behavior to existing components.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users see a branded splash screen within 0.5 seconds of tapping the app icon on every cold launch.
- **SC-002**: The splash-to-main-screen transition completes in under 3 seconds total (splash animation + auth check), with no blank or flickering frames.
- **SC-003**: All screen-to-screen navigations (forward and back) play a visually consistent animated transition.
- **SC-004**: Interactive elements (cards, buttons) provide visual touch feedback within one frame of user input.
- **SC-005**: Animations render at 60fps on mid-range devices (no frame drops visible to the user in normal usage).
- **SC-006**: Users with "reduce motion" enabled experience the app without any distracting animations (instant transitions, no scale effects).
- **SC-007**: Zero new hardcoded color or spacing values introduced — all animation styling uses existing design tokens.
- **SC-008**: All existing 194+ tests continue to pass with no regressions.

## Assumptions

- The app icon/logo asset is available or can be composed from the existing KSEB branding (primary color, app name text). No external designer asset is needed.
- The existing design-token system from feature 002 provides all necessary styling constants.
- The platform's built-in animation framework is sufficient — no third-party animation packages are required.
- The platform provides accessibility queries to detect reduced-motion user preferences.
- Performance on mid-range devices (e.g., Samsung Galaxy A-series, 3–4 year old) is the baseline target.
