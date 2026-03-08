# Widget Library Contract

**Feature**: `002-ui-design-system` | **Date**: 2026-03-08

> This document defines the public API (constructor parameters and behavior) for each shared widget in the design system. These are the contracts that screen code programs against.

---

## AppBarBuilder

**File**: `lib/components/common/app_bar_builder.dart`  
**FR**: FR-007

### Constructor

```dart
AppBar buildAppBar({
  required String title,
  List<Widget>? actions,
  Widget? leading,
  bool centerTitle = true,
  bool automaticallyImplyLeading = true,
  PreferredSizeWidget? bottom,
})
```

### Behavior

- Returns a standard `AppBar` with:
  - `backgroundColor`: `AppColors.surface`
  - `foregroundColor`: `AppColors.textPrimary`
  - `elevation`: 0.5
  - `surfaceTintColor`: transparent
  - `shadowColor`: `AppColors.shadowLight`
  - `centerTitle`: as provided (default: true)
  - `titleTextStyle`: `AppTypography.headingStyle`
- Identical styling is also set in `AppBarTheme` in the root `ThemeData`, so screens using bare `AppBar(title: Text(...))` also inherit these values.

---

## AppCard

**File**: `lib/components/common/app_card.dart`  
**FR**: FR-008

### Constructor

```dart
AppCard({
  required Widget child,
  Color? accentColor,       // Optional colored left/full border
  EdgeInsetsGeometry? padding,  // Override default internal padding
  VoidCallback? onTap,     // Makes card tappable with InkWell
  Key? key,
})
```

### Behavior

- **Default variant** (no `accentColor`): Renders with `AppDecorations.modernCardDecoration` — surface background, `radiusDefault` (16) border radius, `shadowLight` (2-layer shadow), `AppSpacing.base` (16) internal padding.
- **Accent variant** (with `accentColor`): Renders with `AppDecorations.modernCardDecorationWithColor(accentColor)` — same as default plus a 1px border at 10% opacity of the accent color.
- When `onTap` is provided, wraps content in an `InkWell` with the card's border radius for proper splash clipping.
- `padding` overrides the default `AppSpacing.base` internal padding when provided.

---

## AppButton

**File**: `lib/components/common/app_button.dart`  
**FR**: FR-009

### Types

```dart
enum AppButtonVariant { primary, outline, destructive, text }
```

### Constructor

```dart
AppButton({
  required String label,
  required VoidCallback? onPressed,  // null = disabled state
  AppButtonVariant variant = AppButtonVariant.primary,
  bool isLoading = false,
  bool fullWidth = true,
  IconData? icon,
  Key? key,
})
```

### Behavior by Variant

| Property | `primary` | `outline` | `destructive` | `text` |
|----------|-----------|-----------|---------------|--------|
| Height | 56 (responsive) | 56 (responsive) | 56 (responsive) | intrinsic |
| Background | `primaryGradient` | transparent | `AppColors.error` | transparent |
| Border | none | 1.5px `AppColors.primary` | none | none |
| Border Radius | `radiusDefault` (16) | `radiusDefault` (16) | `radiusDefault` (16) | `radiusSm` (8) |
| Text Color | `AppColors.textOnPrimary` | `AppColors.primary` | `AppColors.textOnPrimary` | `AppColors.primary` |
| Text Style | `bodyMediumStyle`, w600 | `bodyMediumStyle`, w600 | `bodyMediumStyle`, w600 | `bodyStyle` |

### Common Behavior

- **Loading state**: When `isLoading` is true, replaces label with `CircularProgressIndicator` using contrasting color. `onPressed` is ignored.
- **Disabled state**: When `onPressed` is null, renders at 50% opacity. Pointer events are ignored.
- **Icon**: When `icon` is provided, renders icon before label with `AppSpacing.sm` (8) gap.
- **Full width**: When `fullWidth` is true (default), button stretches to parent width. When false, wraps content.

---

## AppTextField

**File**: `lib/components/common/app_text_field.dart`  
**FR**: FR-010

### Constructor

```dart
AppTextField({
  required String label,
  TextEditingController? controller,
  String? hintText,
  String? errorText,
  bool obscureText = false,
  TextInputType? keyboardType,
  int maxLines = 1,
  Widget? prefixIcon,
  Widget? suffixIcon,
  ValueChanged<String>? onChanged,
  String? Function(String?)? validator,
  bool enabled = true,
  Key? key,
})
```

### Behavior

- Renders a `TextFormField` with:
  - Border: `OutlineInputBorder` with `radiusSm` (8) border radius
  - Default border color: `AppColors.grey300`
  - Focused border color: `AppColors.primary`, width 1.5
  - Error border color: `AppColors.error`
  - Label style: `AppTypography.captionStyle`
  - Hint style: `TextStyle(color: AppColors.textPlaceholder)`
  - Error style: `TextStyle(color: AppColors.error, fontSize: AppTypography.fontSizeSM)`
  - Content padding: `AppSpacing.base` horizontal, `AppSpacing.md` vertical
- These defaults also set in `InputDecorationTheme` in root `ThemeData`.

---

## AppLoading

**File**: `lib/components/common/app_loading.dart`  
**FR**: FR-011

### Types

```dart
enum AppLoadingVariant { fullPage, inline, overlay }
```

### Constructor

```dart
AppLoading({
  AppLoadingVariant variant = AppLoadingVariant.fullPage,
  String? message,
  Key? key,
})
```

### Behavior by Variant

| Variant | Layout | Background |
|---------|--------|------------|
| `fullPage` | Centered `CircularProgressIndicator` + optional message below, fills available space | transparent |
| `inline` | Row with small (24dp) spinner + message to the right | transparent |
| `overlay` | Positioned.fill with semi-transparent backdrop + centered spinner + message | `AppColors.black` @ 0.3 alpha |

### Common Behavior

- Spinner color: `AppColors.primary` (via `valueColor: AlwaysStoppedAnimation(AppColors.primary)`)
- Spinner stroke width: 3.0
- Message style: `AppTypography.captionStyle`
- Message spacing: `AppSpacing.md` (12) below spinner (fullPage/overlay) or to the right (inline)

---

## AppEmptyState

**File**: `lib/components/common/app_empty_state.dart`  
**FR**: FR-012

### Constructor

```dart
AppEmptyState({
  required IconData icon,
  required String title,
  String? subtitle,
  String? actionLabel,
  VoidCallback? onAction,
  Key? key,
})
```

### Behavior

- Centered column layout:
  1. Icon: 64dp, color `AppColors.grey400`
  2. Gap: `AppSpacing.base` (16)
  3. Title: `AppTypography.subheadingStyle`
  4. Gap: `AppSpacing.sm` (8) — only if subtitle present
  5. Subtitle: `AppTypography.captionStyle`
  6. Gap: `AppSpacing.lg` (20) — only if action present
  7. Action button: `AppButton(variant: .outline, label: actionLabel)`

---

## AppErrorState

**File**: `lib/components/common/app_error_state.dart`  
**FR**: FR-013

### Constructor

```dart
AppErrorState({
  required String message,
  VoidCallback? onRetry,
  IconData icon = Icons.error_outline,
  Key? key,
})
```

### Behavior

- Centered column layout:
  1. Icon: 56dp, color `AppColors.error`
  2. Gap: `AppSpacing.base` (16)
  3. Message: `AppTypography.bodyStyle`, centered, max 2 lines
  4. Gap: `AppSpacing.base` (16) — only if onRetry present
  5. Retry button: `AppButton(variant: .outline, label: 'Retry', icon: Icons.refresh)`
- This is a **persistent inline widget** that complements `AppToast` (transient). Used for section/page-level failures where the user must explicitly retry.

---

## AppPageWrapper

**File**: `lib/components/common/app_scaffold.dart`  
**FR**: FR-014

### Constructor

```dart
AppPageWrapper({
  required Widget child,
  bool scrollable = true,
  EdgeInsetsGeometry? padding,  // Override default page padding
  Color? backgroundColor,      // Override default background
  Key? key,
})
```

### Behavior

- Default padding: `EdgeInsets.fromLTRB(24, 24, 24, 100)` (with responsive scaling applied via `context.responsivePadding()`)
- Default background: `AppColors.background`
- When `scrollable` is true (default), wraps child in `SingleChildScrollView` with `AlwaysScrollableScrollPhysics`
- Goes inside `Scaffold.body`, not as a `Scaffold` replacement. Screens retain control of `Scaffold` properties (appBar, floatingActionButton, etc.).

---

## Integration: Root ThemeData

**File**: `lib/main.dart`  
**FR**: FR-006, FR-016

### Contract

The root `MaterialApp.theme` MUST be configured as follows:

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textOnPrimary,
    error: AppColors.error,
    onError: AppColors.textOnPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    // ... all roles mapped from AppColors
  ),
  textTheme: GoogleFonts.interTextTheme().copyWith(
    displayLarge: AppTypography.displayLargeStyle,
    displayMedium: AppTypography.displayStyle,
    titleLarge: AppTypography.titleStyle,
    titleMedium: AppTypography.headingStyle,
    titleSmall: AppTypography.subheadingStyle,
    bodyLarge: AppTypography.bodyMediumStyle,
    bodyMedium: AppTypography.bodyStyle,
    bodySmall: AppTypography.captionStyle,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0.5,
    surfaceTintColor: Colors.transparent,
    shadowColor: AppColors.shadowLight,
    centerTitle: true,
    titleTextStyle: AppTypography.headingStyle,
  ),
  cardTheme: CardTheme(
    color: AppColors.surface,
    elevation: 0,  // shadows handled via BoxDecoration
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      borderSide: BorderSide(color: AppColors.error),
    ),
    labelStyle: AppTypography.captionStyle,
    hintStyle: TextStyle(color: AppColors.textPlaceholder),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      minimumSize: Size(0, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      ),
    ),
  ),
)
```

This ensures:
- Framework components inherit correct styling without per-screen overrides
- `primarySwatch: Colors.teal` is eliminated (replaced by `colorScheme`)
- All theme roles reference `AppColors` values — single source of truth
