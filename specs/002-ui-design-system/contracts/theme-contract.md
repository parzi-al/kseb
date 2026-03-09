# Theme Contract

**Feature**: `002-ui-design-system` | **Date**: 2026-03-08

> This document defines the contract between the design token system and Flutter's `ThemeData`. It specifies which theme properties are controlled by the design system and how they map to token values.

---

## ColorScheme Mapping

| ColorScheme Role | AppColors Token | Value |
|------------------|----------------|-------|
| `brightness` | — | `Brightness.light` |
| `primary` | `AppColors.primary` | `#FF6B35` |
| `onPrimary` | `AppColors.textOnPrimary` | `#FFFFFF` |
| `primaryContainer` | `AppColors.primaryWithLowOpacity` | primary @ 0.08 |
| `onPrimaryContainer` | `AppColors.primaryDark` | `#E64A19` |
| `secondary` | `AppColors.secondary` | `#6C5CE7` |
| `onSecondary` | `AppColors.textOnPrimary` | `#FFFFFF` |
| `secondaryContainer` | `AppColors.secondary` @ 0.08 | computed |
| `onSecondaryContainer` | `AppColors.secondary` | `#6C5CE7` |
| `tertiary` | `AppColors.accent` | `#00D4AA` |
| `onTertiary` | `AppColors.textOnPrimary` | `#FFFFFF` |
| `error` | `AppColors.error` | `#E74C3C` |
| `onError` | `AppColors.textOnPrimary` | `#FFFFFF` |
| `surface` | `AppColors.surface` | `#FFFFFF` |
| `onSurface` | `AppColors.textPrimary` | `#212529` |
| `surfaceContainerHighest` | `AppColors.grey200` | `#E9ECEF` |
| `outline` | `AppColors.grey300` | `#DEE2E6` |
| `outlineVariant` | `AppColors.grey200` | `#E9ECEF` |
| `shadow` | `AppColors.cardShadow` | `#08000000` |

---

## Component Theme Mapping

### AppBarTheme

| Property | Token | Value |
|----------|-------|-------|
| `backgroundColor` | `AppColors.surface` | `#FFFFFF` |
| `foregroundColor` | `AppColors.textPrimary` | `#212529` |
| `elevation` | — | `0.5` |
| `surfaceTintColor` | — | `Colors.transparent` |
| `shadowColor` | `AppColors.shadowLight` | black @ 0.04 |
| `centerTitle` | — | `true` |
| `titleTextStyle` | `AppTypography.headingStyle` | Inter 18sp w600 |

### CardTheme

| Property | Token | Value |
|----------|-------|-------|
| `color` | `AppColors.surface` | `#FFFFFF` |
| `elevation` | — | `0` (shadows via BoxDecoration) |
| `shape` | `AppSpacing.radiusDefault` | `RoundedRectangleBorder(borderRadius: 16)` |
| `margin` | — | `EdgeInsets.zero` |

### InputDecorationTheme

| Property | Token | Value |
|----------|-------|-------|
| `border` radius | `AppSpacing.radiusSm` | `8.0` |
| `focusedBorder` color | `AppColors.primary` | `#FF6B35`, width 1.5 |
| `errorBorder` color | `AppColors.error` | `#E74C3C` |
| `labelStyle` | `AppTypography.captionStyle` | Inter 12sp w400 grey500 |
| `hintStyle` color | `AppColors.textPlaceholder` | `#CED4DA` |
| `contentPadding` | `AppSpacing.base` / `AppSpacing.md` | 16h, 12v |

### ElevatedButtonTheme

| Property | Token | Value |
|----------|-------|-------|
| `backgroundColor` | `AppColors.primary` | `#FF6B35` |
| `foregroundColor` | `AppColors.textOnPrimary` | `#FFFFFF` |
| `minimumSize` height | — | `56.0` |
| `shape` radius | `AppSpacing.radiusDefault` | `16.0` |
| `textStyle` | `AppTypography.bodyMediumStyle` | Inter 14sp w500 |

### TextButtonTheme

| Property | Token | Value |
|----------|-------|-------|
| `foregroundColor` | `AppColors.primary` | `#FF6B35` |
| `textStyle` | `AppTypography.bodyStyle` | Inter 14sp w400 |

### FloatingActionButtonTheme

| Property | Token | Value |
|----------|-------|-------|
| `backgroundColor` | `AppColors.primary` | `#FF6B35` |
| `foregroundColor` | `AppColors.textOnPrimary` | `#FFFFFF` |
| `shape` radius | `AppSpacing.radiusDefault` | `16.0` |

---

## Invariants

1. The root `ThemeData` MUST use `useMaterial3: true`
2. The root `ThemeData` MUST NOT set `primarySwatch` — use `colorScheme` instead
3. Every `ColorScheme` role MUST map to an `AppColors` token — no hex literals in theme configuration
4. Every component theme MUST reference token constants — no magic numbers
5. The `textTheme` MUST be built from `AppTypography` styles applied to `GoogleFonts.interTextTheme()`
6. Framework widgets (AppBar, Card, TextField, Button) that receive no explicit styling MUST render correctly per the design system due to theme inheritance alone
