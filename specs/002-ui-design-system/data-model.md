# Data Model: Uniform UI Design System

**Feature**: `002-ui-design-system` | **Date**: 2026-03-08

> This feature has no persistent data entities (no Firestore schemas, no API models). The "data model" is the **design token catalog** — the complete set of named constants that form the single source of truth for all visual styling.

## Entity: Color Tokens (`AppColors`)

**Source file**: `lib/utils/app_colors.dart` (refactored — colors only)

### Primary Palette

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `primary` | `#FF6B35` | 255, 107, 53 | Primary actions, buttons, icons, active states |
| `primaryLight` | `#FF8A65` | 255, 138, 101 | Gradient end, hover states, lighter accents |
| `primaryDark` | `#E64A19` | 230, 74, 25 | Pressed states, emphasis |

### Secondary & Accent

| Token | Hex | Usage |
|-------|-----|-------|
| `secondary` | `#6C5CE7` | Dashboard card accents, secondary actions |
| `accent` | `#00D4AA` | Dashboard card accents, highlights |
| `purple` | `#9B59B6` | Supplementary accent |

### Status Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `success` | `#27AE60` | Success badges, attendance present markers |
| `warning` | `#F39C12` | Warning toasts, debug indicators |
| `error` | `#E74C3C` | Error states, destructive actions, logout |
| `info` | `#3498DB` | Info toasts, stat highlights |

### Neutral Scale

| Token | Hex | Role |
|-------|-----|------|
| `white` | `#FFFFFF` | Pure white |
| `black` | `#1A1A1A` | Softer black |
| `grey50` | `#FCFCFC` | Ultra-light surface variant |
| `grey100` | `#F8F9FA` | Light background |
| `grey200` | `#E9ECEF` | Borders |
| `grey300` | `#DEE2E6` | Dividers |
| `grey400` | `#CED4DA` | Placeholders |
| `grey500` | `#6C757D` | Secondary text |
| `grey600` | `#495057` | Body text |
| `grey700` | `#343A40` | Headings |
| `grey800` | `#212529` | Primary text |
| `grey900` | `#1A1A1A` | Darkest |

### Semantic Aliases

| Token | Maps to | Role |
|-------|---------|------|
| `background` | `white` | Scaffold background |
| `surface` | `white` | Card/AppBar surface |
| `surfaceVariant` | `grey50` | Alternate surface |
| `cardShadow` | `#08000000` | Subtle card shadow |
| `textPrimary` | `grey800` | Headings, main content |
| `textSecondary` | `grey500` | Supporting text |
| `textTertiary` | `grey400` | Subtle/disabled text |
| `textOnPrimary` | `white` | Text on primary-colored bg |
| `textOnDark` | `white` | Text on dark bg |
| `textPlaceholder` | `grey400` | Input placeholders |

### Opacity Variants (computed)

| Token | Base | Alpha | Usage |
|-------|------|-------|-------|
| `primaryWithLowOpacity` | primary | 0.08 | Tinted backgrounds |
| `primaryWithMediumOpacity` | primary | 0.12 | Hover overlays |
| `primaryWithHighOpacity` | primary | 0.16 | Active overlays |
| `whiteWithLowOpacity` | white | 0.1 | Glass effect |
| `greyWithLowOpacity` | grey200 | 0.5 | Subtle overlays |
| `shadowLight` | black | 0.04 | Card shadow (light) |
| `shadowMedium` | black | 0.08 | Card shadow (medium) |
| `shadowDark` | black | 0.12 | Card shadow (heavy) |

### Gradients

| Token | Colors | Direction | Usage |
|-------|--------|-----------|-------|
| `primaryGradient` | primary → primaryLight | topLeft → bottomRight | Primary action buttons |
| `surfaceGradient` | white → grey50 | topCenter → bottomCenter | Subtle surface gradient |
| `cardGradient(color)` | color@0.08 → color@0.04 | topLeft → bottomRight | Dashboard card tints |

### Dashboard Card Colors (ordered list)

| Index | Color | Hex | Associated card |
|-------|-------|-----|-----------------|
| 0 | secondary | `#6C5CE7` | Attendance |
| 1 | accent | `#00D4AA` | History |
| 2 | info | `#3498DB` | Worksheet |
| 3 | primary | `#FF6B35` | Material |

---

## Entity: Typography Tokens (`AppTypography`)

**Source file**: `lib/utils/app_typography.dart` (new)

### Font Size Scale

| Token | Value (sp) | Usage |
|-------|-----------|-------|
| `fontSizeXS` | 11.0 | Extra-small text |
| `fontSizeSM` | 12.0 | Captions, labels |
| `fontSizeBase` | 14.0 | Body text |
| `fontSizeLG` | 16.0 | Subheadings |
| `fontSizeXL` | 18.0 | Section headers |
| `fontSize2XL` | 20.0 | Page titles |
| `fontSize3XL` | 24.0 | Main headings |
| `fontSize4XL` | 28.0 | Display text |

### Named TextStyles

| Token | Size | Weight | Color | Usage |
|-------|------|--------|-------|-------|
| `displayLargeStyle` | 28 | w800 | textPrimary | Hero text, KSEB branding |
| `displayStyle` | 24 | w700 | textPrimary | User name, large numbers |
| `titleStyle` | 20 | w700 | textPrimary | Section titles |
| `headingStyle` | 18 | w600 | textPrimary | AppBar titles, section headers |
| `subheadingStyle` | 16 | w600 | textPrimary | Sub-section headers |
| `bodyMediumStyle` | 14 | w500 | textPrimary | Emphasized body text |
| `bodyStyle` | 14 | w400 | textPrimary | Default body text |
| `captionStyle` | 12 | w400 | textSecondary | Labels, secondary info |

### TextTheme Mapping

| AppTypography token | → Material TextTheme slot |
|---------------------|---------------------------|
| `displayLargeStyle` | `displayLarge` |
| `displayStyle` | `displayMedium` |
| `titleStyle` | `titleLarge` |
| `headingStyle` | `titleMedium` |
| `subheadingStyle` | `titleSmall` |
| `bodyMediumStyle` | `bodyLarge` |
| `bodyStyle` | `bodyMedium` |
| `captionStyle` | `bodySmall` |

### Font Family

- **Primary**: Google Fonts Inter (applied via `GoogleFonts.interTextTheme()`)
- **Fallback**: Platform default

---

## Entity: Spacing Tokens (`AppSpacing`)

**Source file**: `lib/utils/app_spacing.dart` (new)

### Spacing Scale

| Token | Value (dp) | Usage |
|-------|-----------|-------|
| `xs` | 4.0 | Tightest spacing (icon-to-text) |
| `sm` | 8.0 | Small gaps (between related items) |
| `md` | 12.0 | Medium gaps |
| `base` | 16.0 | Default spacing (between sections, card padding) |
| `lg` | 20.0 | Large gaps (section separation) |
| `xl` | 24.0 | Extra-large (page padding, major sections) |
| `xxl` | 32.0 | Section breaks |
| `page` | 40.0 | Page-level top/bottom padding |

### Border Radius Scale

| Token | Value (dp) | Usage |
|-------|-----------|-------|
| `radiusSm` | 8.0 | Small elements (chips, tags, input borders) |
| `radiusMd` | 12.0 | Medium elements (badges, small cards) |
| `radiusDefault` | 16.0 | Standard card/button radius (homepage standard) |
| `radiusLg` | 20.0 | Large containers (dialogs, bottom sheets) |
| `radiusPill` | 100.0 | Pill-shaped elements (badges, pill buttons) |

### Elevation / Shadow Presets

| Token | Shadows | Usage |
|-------|---------|-------|
| `shadowNone` | none | Flat elements |
| `shadowLight` | blur:8 offset:0,2 @0.04 + blur:2 offset:0,1 @0.08 | Standard cards (homepage standard) |
| `shadowMedium` | blur:12 offset:0,4 @0.08 + blur:4 offset:0,2 @0.12 | Elevated cards, dialogs |
| `shadowHeavy` | blur:20 offset:0,8 @0.12 + blur:6 offset:0,3 @0.16 | Modals, overlays |

### Responsive Scaling

| Method | Input | Breakpoints | Behavior |
|--------|-------|-------------|----------|
| `responsiveHeight(base)` | double | Linear: screenH / 844 | iPhone 14 baseline |
| `responsiveWidth(base)` | double | Linear: screenW / 390 | iPhone 14 baseline |
| `responsivePadding(base)` | double | <700: ×0.6, <800: ×0.8, ≥800: ×1.0 | 3-tier step |
| `responsiveSpacing(base)` | double | <700: ×0.5, <800: ×0.75, ≥800: ×1.0 | 3-tier step |
| `responsiveFontSize(base)` | double | <700: ×0.85, <800: ×0.92, ≥800: ×1.0 | 3-tier step |
| `responsiveTextStyle(style)` | TextStyle | Delegates to `responsiveFontSize` | Wraps font scaling |

---

## Entity: Decoration Tokens (`AppDecorations`)

**Source file**: `lib/utils/app_decorations.dart` (new)

### Card Decorations

| Token | Background | Radius | Shadow | Border | Usage |
|-------|-----------|--------|--------|--------|-------|
| `modernCardDecoration` | surface | 16 | shadowLight (2-layer) | none | Standard card |
| `modernCardDecorationWithColor(color)` | surface | 16 | shadowLight (1-layer) | color@0.1, 1px | Dashboard colored cards |

---

## Relationships

```
AppColors ←── AppTypography (references textPrimary, textSecondary for style colors)
AppColors ←── AppDecorations (references surface, shadowLight, shadowMedium for decorations)
AppColors ←── AppSpacing (no dependency — pure numeric constants)
AppSpacing ←── AppDecorations (references radiusDefault for card border radius)
ThemeData ←── AppColors + AppTypography + AppSpacing (assembled in main.dart)
SharedWidgets ←── All token files (each widget references tokens from 1-4 files)
Screens ←── SharedWidgets + token files (screens use widgets and may reference tokens directly for unique layouts)
```

## Validation Rules

- All color hex values MUST be 8-digit ARGB format (0xAARRGGBB) or 6-digit RGB with full alpha.
- Spacing scale MUST be monotonically increasing: xs < sm < md < base < lg < xl < xxl < page.
- Border radius scale MUST be monotonically increasing: radiusSm < radiusMd < radiusDefault < radiusLg < radiusPill.
- Font size scale MUST be monotonically increasing: fontSizeXS < fontSizeSM < fontSizeBase < ... < fontSize4XL.
- Named TextStyles MUST reference font sizes from the font size scale (no arbitrary values).
- Named TextStyles MUST reference colors from the color token set (no raw hex in styles).
- Shadow presets MUST use shadow colors from the color token set (shadowLight, shadowMedium, shadowDark).

## State Transitions

Not applicable — design tokens are immutable constants with no state changes.
