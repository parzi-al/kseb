# Feature Specification: Uniform UI Design System

**Feature Branch**: `002-ui-design-system`  
**Created**: 2026-03-08  
**Status**: Draft  
**Input**: User description: "Implement uniform UI design system taking inspiration from the homescreen and attendance screen. Ensure all screens follow the same visual system used in Homepage and Attendance."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent Visual Identity Across All Screens (Priority: P1)

As a user navigating between screens, I experience a unified visual identity — the same colors, typography, spacing, card layouts, and button styles — so the app feels polished and professionally built rather than a patchwork of different designs.

**Why this priority**: Visual consistency is the core deliverable of this feature. Without it, nothing else matters — every screen must look like it belongs to the same application.

**Independent Test**: Navigate through every screen in the app (Home → Attendance → Staff Management → Worksheet → Material Management → Bonus Management → Login) and verify that colors, fonts, card shapes, button styles, and spacing are visually uniform.

**Acceptance Scenarios**:

1. **Given** a user is on the Home screen, **When** they navigate to any other screen, **Then** the color palette, typography scale, card styling, and button appearance are visually identical in style.
2. **Given** a user views any card element on any screen, **When** they compare it to cards on the Home screen, **Then** the border radius, shadow, padding, and background color match.
3. **Given** a user sees any button on any screen, **When** they compare it to buttons on the Home or Attendance screen, **Then** the button height, border radius, color, and text styling match the same category of button.
4. **Given** a user reads text on any screen, **When** they compare headings, body text, and captions across screens, **Then** the font sizes, weights, and colors are drawn from the same predefined typography scale.

---

### User Story 2 - Reusable Widget Library for Developers (Priority: P1)

As a developer maintaining or extending the app, I use a shared library of pre-built widgets (buttons, cards, input fields, loading indicators, error/empty states, page scaffolds) so I never need to write inline styling and every new screen automatically matches the design system.

**Why this priority**: Without reusable widgets, visual consistency degrades over time as developers re-implement styles differently. This story is the enforcement mechanism for Story 1.

**Independent Test**: A developer can build a new screen using only the shared widget library and standard design tokens — no inline `TextStyle`, `BoxDecoration`, `EdgeInsets`, or raw `Colors.*` references needed.

**Acceptance Scenarios**:

1. **Given** a developer needs a primary action button, **When** they use the shared button widget, **Then** it renders with the correct gradient, height, border radius, and text style without any inline customization.
2. **Given** a developer needs a content card, **When** they use the shared card widget, **Then** it renders with the standard shadow, border radius, padding, and background without any inline decoration.
3. **Given** a developer needs a text input field, **When** they use the shared input field widget, **Then** it renders with the standard border, focus color, label style, and error style.
4. **Given** a developer needs a loading indicator, **When** they use the shared loading widget, **Then** it renders with the standard spinner color, size, and optional message — consistently across all contexts (full-page, inline, overlay).

---

### User Story 3 - Consistent Loading and Error Feedback (Priority: P2)

As a user waiting for data to load or encountering an error, I see the same loading animation and error presentation on every screen, so I always know what the app is doing and how to recover from problems.

**Why this priority**: Loading and error states are high-frequency UI moments. Inconsistent treatment creates confusion and undermines perceived quality.

**Independent Test**: Trigger loading states and error conditions on each screen and verify the visual treatment is identical.

**Acceptance Scenarios**:

1. **Given** any screen is loading data, **When** I see a loading indicator, **Then** it uses the same spinner style, color, and optional accompanying text on every screen.
2. **Given** any screen encounters an error, **When** the error is displayed, **Then** it uses the same error card/banner with consistent icon, color, message format, and retry action.
3. **Given** any screen has no data to display, **When** the empty state is shown, **Then** it uses the same empty-state layout with consistent icon, title, subtitle, and optional action button.

---

### User Story 4 - Responsive Spacing on All Screens (Priority: P2)

As a user on different device sizes (phones, tablets), I see properly scaled spacing, font sizes, and touch targets on every screen — not just the Home and Login screens.

**Why this priority**: The app already has responsive helpers but they are only applied on two screens. Extending them everywhere ensures the app works well across the device spectrum.

**Independent Test**: Run the app on a small phone (360dp wide), a standard phone (400dp wide), and a tablet (600dp+ wide) and verify that spacing, font sizes, and touch targets scale appropriately on every screen.

**Acceptance Scenarios**:

1. **Given** a user opens any screen on a small phone, **When** they view the layout, **Then** padding, spacing, and font sizes are scaled down proportionally using the responsive system.
2. **Given** a user opens any screen on a tablet, **When** they view the layout, **Then** content uses available space appropriately with scaled-up spacing and touch targets.

---

### User Story 5 - Elimination of Inline Styling (Priority: P3)

As a code reviewer, when I review any screen file, I see zero inline `TextStyle` constructors, zero inline `BoxDecoration` constructors for cards, zero raw `Colors.*` or `SizedBox(height: N)` for standard spacing — all styling references point to the shared design system.

**Why this priority**: This is the code-quality enforcement that prevents design drift. Lower priority because it's a developer-facing concern, not user-facing — but essential for long-term maintainability.

**Independent Test**: Run a static analysis or manual audit of all screen files and confirm no inline styling exists for standardized elements.

**Acceptance Scenarios**:

1. **Given** any screen file in the app, **When** a reviewer inspects it, **Then** all color references use design tokens (not raw `Colors.*` or hex literals).
2. **Given** any screen file in the app, **When** a reviewer inspects it, **Then** all text styles use predefined typography tokens (not inline `TextStyle` constructors).
3. **Given** any screen file in the app, **When** a reviewer inspects it, **Then** all standard spacing uses defined spacing constants (not arbitrary `SizedBox` values).

---

### Edge Cases

- What happens when the app theme is applied but a third-party widget (e.g., TableCalendar) does not respect custom tokens? The design system should provide override/wrapper mechanisms for third-party widget theming.
- What happens if a screen needs a one-off color or spacing value not in the token system? The system should allow documented exceptions without breaking the constraint of "no inline styling" — an explicit escape hatch with code comments is acceptable for truly unique cases.
- What happens when the app is used in dark mode or high-contrast accessibility mode? The design token system should be structured to support future theme variants even if dark mode is not implemented now.
- What happens when a loading state extends beyond 10 seconds? The loading indicator should remain visible and stable (no layout shift) until data arrives or a timeout error is shown.

## Requirements *(mandatory)*

### Functional Requirements

#### Design Token System

- **FR-001**: The app MUST define a single authoritative set of color tokens (primary, secondary, accent, success, warning, error, info, background, surface, text-primary, text-secondary, border, shadow) that all screens reference.
- **FR-002**: The app MUST define a single authoritative typography scale with named styles (display-large, display, title, heading, subheading, body-medium, body, caption) that all screens reference.
- **FR-003**: The app MUST define a single authoritative set of spacing constants (extra-small: 4, small: 8, medium: 12, regular: 16, large: 20, extra-large: 24, section: 32, page: 40) that all screens reference for margins, padding, and gaps.
- **FR-004**: The app MUST define a single authoritative set of border radius constants (small: 8, medium: 12, default: 16, large: 20, pill: 100) that all screens reference.
- **FR-005**: The app MUST define a single authoritative set of shadow/elevation presets (none, light, medium, heavy) that all screens reference for card and container depth.
- **FR-006**: The app MUST configure its root-level theme to use the design tokens so that standard framework components (AppBar, buttons, inputs, cards) inherit correct styling automatically.

#### Reusable Widget Library

- **FR-007**: The app MUST provide a shared AppBar builder widget that accepts a title and optional actions, rendering with the standard surface background, text color, elevation, and centering defined by the design system.
- **FR-008**: The app MUST provide a shared card widget that renders with the standard background, border radius, shadow, and internal padding — with an optional colored border variant.
- **FR-009**: The app MUST provide shared button widgets covering the standard variants: primary (gradient), secondary (outline), destructive (error), and text-only — each with the correct height, border radius, text style, and color.
- **FR-010**: The app MUST provide a shared text input field widget that renders with the standard border, focus color, label style, hint style, error style, and border radius.
- **FR-011**: The app MUST provide a shared loading indicator widget with variants for full-page, inline, and overlay contexts — all using the standard spinner color and style.
- **FR-012**: The app MUST provide a shared empty-state widget displaying a centered icon, title, subtitle, and optional action button.
- **FR-013**: The app MUST provide a shared error-state widget displaying an error icon, message, and retry button with consistent styling.
- **FR-014**: The app MUST provide a shared page scaffold widget that applies standard page padding, background color, and optional scroll behavior so every screen has uniform outer spacing.

#### Screen Migration

- **FR-015**: All existing screens (Home, Attendance, Login, Staff Management, Worksheet, Material Management, Bonus Management, and their sub-screens) MUST be updated to use the shared design tokens and reusable widgets — removing all inline styling for standardized elements.
- **FR-016**: The app's root theme configuration MUST be updated so that the primary color swatch matches the design token primary color (currently orange `#FF6B35`), resolving the existing conflict with teal.
- **FR-017**: All responsive helpers (responsive padding, spacing, font sizing) MUST be applied consistently across every screen — not just Home and Login.
- **FR-018**: All uses of deprecated styling APIs (e.g., `Color.withOpacity()`) MUST be replaced with current equivalents (e.g., `Color.withValues(alpha:)`).

### Key Entities

- **Design Token**: A named, reusable styling value (color, size, weight, radius, shadow) that serves as the single source of truth for a visual property. Tokens are organized into categories: color, typography, spacing, radius, elevation.
- **Shared Widget**: A pre-built, parameterized UI component (button, card, input, loading indicator, scaffold) that encapsulates the design tokens and exposes only semantic configuration (e.g., "primary button with label 'Save'") — not raw styling properties.
- **Screen**: A full-page view in the app that must adopt the design system by using shared widgets and design tokens exclusively for all standardized visual elements.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of screens in the app use the shared design tokens for colors — zero raw color literals (`Colors.*` or hex values) appear in screen files for standardized elements.
- **SC-002**: 100% of screens use the shared typography scale — zero inline `TextStyle` constructors appear in screen files for standardized text categories.
- **SC-003**: 100% of card-style containers across all screens render with identical border radius, shadow, and padding (within the defined token values).
- **SC-004**: 100% of primary action buttons across all screens render with identical height, border radius, gradient, and text style.
- **SC-005**: Users perceive visual consistency — a side-by-side comparison of any two screens shows matching visual rhythm (spacing, alignment, card sizing, typography hierarchy).
- **SC-006**: A new screen can be built by a developer using only the shared widget library and design tokens, with zero inline styling, in under 30 minutes for a standard form/list layout.
- **SC-007**: Loading indicators on all screens use the same visual treatment (same spinner color, same size, same optional message pattern).
- **SC-008**: Empty and error states on all screens use the same visual treatment (same icon style, same message layout, same action button style).
- **SC-009**: The app renders correctly on devices from 360dp to 600dp+ width, with spacing and font sizes scaling via the responsive system on every screen.
- **SC-010**: The root theme configuration aligns with the design token system — no conflicts between framework theme values and custom design tokens.

## Assumptions

- **A-001**: The existing color palette defined in `AppColors` (primary orange `#FF6B35`, secondary purple, accent teal, etc.) is the correct and approved palette. No color redesign is needed — only consistent application.
- **A-002**: The existing typography scale in `AppColors` (12–28sp range, Inter font family) is the correct and approved scale. No typographic redesign is needed — only consistent application and extraction into a proper token structure.
- **A-003**: The responsive helpers (`getResponsivePadding`, `getResponsiveSpacing`, `getResponsiveFontSize`) already produce correct values. They just need to be applied to all screens, not redesigned.
- **A-004**: Dark mode is out of scope for this feature. However, the token system should be structured so that adding dark mode later requires only defining an alternate token set — not restructuring the architecture.
- **A-005**: Accessibility compliance (WCAG contrast ratios, minimum touch target sizes) is out of scope but the design system should not introduce new violations.
- **A-006**: Third-party widgets (e.g., TableCalendar) will be themed via wrapper widgets or configuration overrides to match the design system as closely as the library allows.
- **A-007**: The `AppColors` utility file will be refactored and split into focused modules (colors, typography, spacing, decorations) rather than remaining a single overloaded file.
