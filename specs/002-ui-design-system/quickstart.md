# Quickstart: KSEB Design System

**Feature**: `002-ui-design-system` | **Date**: 2026-03-08

> How to use the design system when building or modifying screens.

---

## 1. Import the Design Tokens

Single import for all tokens:

```dart
import 'package:kseb/utils/app_colors.dart';
import 'package:kseb/utils/app_typography.dart';
import 'package:kseb/utils/app_spacing.dart';
import 'package:kseb/utils/app_decorations.dart';
```

---

## 2. Use Shared Widgets

### Buttons

```dart
// Primary action (gradient, full-width)
AppButton(
  label: 'Mark Attendance',
  variant: AppButtonVariant.primary,
  onPressed: () => _markAttendance(),
)

// Outline action
AppButton(
  label: 'Cancel',
  variant: AppButtonVariant.outline,
  onPressed: () => Navigator.pop(context),
)

// Destructive action
AppButton(
  label: 'Delete',
  variant: AppButtonVariant.destructive,
  onPressed: () => _delete(),
  icon: Icons.delete,
)

// Loading state
AppButton(
  label: 'Saving...',
  variant: AppButtonVariant.primary,
  onPressed: null,
  isLoading: true,
)
```

### Cards

```dart
// Standard card
AppCard(
  child: Column(
    children: [
      Text('Card Title', style: AppTypography.subheadingStyle),
      SizedBox(height: AppSpacing.sm),
      Text('Card body text', style: AppTypography.bodyStyle),
    ],
  ),
)

// Colored accent card (dashboard style)
AppCard(
  accentColor: AppColors.secondary,
  onTap: () => _navigate(),
  child: Text('Attendance'),
)
```

### Text Fields

```dart
AppTextField(
  label: 'Employee Name',
  controller: _nameController,
  hintText: 'Enter full name',
  validator: (v) => v?.isEmpty == true ? 'Required' : null,
)
```

### Loading States

```dart
// Full page loading (default)
AppLoading()

// With message
AppLoading(message: 'Loading attendance...')

// Inline (inside a row or list)
AppLoading(variant: AppLoadingVariant.inline, message: 'Fetching...')

// Overlay (on top of content)
AppLoading(variant: AppLoadingVariant.overlay)
```

### Empty & Error States

```dart
// Empty state
AppEmptyState(
  icon: Icons.inbox_outlined,
  title: 'No records found',
  subtitle: 'Attendance records will appear here',
  actionLabel: 'Refresh',
  onAction: () => _refresh(),
)

// Error state (persistent inline)
AppErrorState(
  message: 'Failed to load attendance data',
  onRetry: () => _loadData(),
)
```

### Page Scaffold

```dart
// Standard scrollable page
Scaffold(
  appBar: buildAppBar(title: 'Attendance'),
  body: AppPageWrapper(
    child: Column(
      children: [
        // page content...
      ],
    ),
  ),
)

// Non-scrollable page with custom padding
Scaffold(
  appBar: buildAppBar(title: 'Dashboard'),
  body: AppPageWrapper(
    scrollable: false,
    padding: EdgeInsets.all(AppSpacing.base),
    child: GridView(...),
  ),
)
```

---

## 3. Use Design Tokens Directly

For custom layouts that don't use shared widgets:

### Colors

```dart
// DO: Use tokens
Container(color: AppColors.primary)
Icon(Icons.check, color: AppColors.success)

// DON'T: Use raw colors
Container(color: Color(0xFFFF6B35))  // ❌
Icon(Icons.check, color: Colors.green)  // ❌
```

### Typography

```dart
// DO: Use token styles
Text('Hello', style: AppTypography.headingStyle)

// With responsive scaling (when needed)
Text('Hello', style: context.responsiveTextStyle(AppTypography.headingStyle))

// DON'T: Inline TextStyle
Text('Hello', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))  // ❌
```

### Spacing

```dart
// DO: Use spacing tokens
SizedBox(height: AppSpacing.base)
Padding(padding: EdgeInsets.all(AppSpacing.xl))

// With responsive scaling (when needed)
SizedBox(height: context.responsiveSpacing(AppSpacing.lg))

// DON'T: Magic numbers
SizedBox(height: 16)  // ❌
Padding(padding: EdgeInsets.all(24))  // ❌
```

### Border Radius

```dart
// DO: Use radius tokens
BorderRadius.circular(AppSpacing.radiusDefault)

// DON'T: Magic numbers
BorderRadius.circular(16)  // ❌
```

### Shadows

```dart
// DO: Use decoration tokens
Container(decoration: AppDecorations.modernCardDecoration)

// DON'T: Inline BoxDecoration with shadows
Container(decoration: BoxDecoration(
  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]  // ❌
))
```

---

## 4. Responsive Helpers

Available as `BuildContext` extensions:

```dart
// Responsive spacing
context.responsivePadding(AppSpacing.xl)   // Scales 24 → 14.4/19.2/24 based on screen
context.responsiveSpacing(AppSpacing.lg)   // Scales 20 → 10/15/20 based on screen
context.responsiveFontSize(18.0)           // Scales 18 → 15.3/16.56/18 based on screen
context.responsiveTextStyle(AppTypography.headingStyle)  // Applies font scaling
context.responsiveHeight(56.0)             // Linear scale against 844px baseline
context.responsiveWidth(200.0)             // Linear scale against 390px baseline
```

---

## 5. Escape Hatch

For truly unique one-off values not covered by the token system:

```dart
// Document the exception with a comment
Container(
  // DS-EXCEPTION: Calendar cell requires 48dp for touch target compliance
  height: 48.0,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    color: AppColors.primaryWithLowOpacity,
  ),
)
```

The `// DS-EXCEPTION:` comment makes exceptions searchable and auditable.

---

## 6. Testing Your Screen

```dart
testWidgets('MyScreen uses design tokens', (tester) async {
  GoogleFonts.config.allowRuntimeFetching = false;

  await tester.pumpWidget(MaterialApp(
    theme: createAppTheme(),  // Uses the shared theme builder
    home: MyScreen(),
  ));

  // Verify card uses correct decoration
  final container = tester.widget<Container>(find.byType(Container).first);
  final decoration = container.decoration as BoxDecoration;
  expect(decoration.borderRadius, BorderRadius.circular(AppSpacing.radiusDefault));

  // Verify text uses token style
  final title = tester.widget<Text>(find.text('My Title'));
  expect(title.style?.fontSize, AppTypography.headingStyle.fontSize);
});
```
