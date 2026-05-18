/// Quickstart validation test: builds a minimal screen using only shared widgets
/// and design tokens. Verifies zero inline styling is needed for a standard screen.
///
/// Task T070 — validates quickstart.md integration scenarios.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kseb/utils/app_colors.dart';
import 'package:kseb/utils/app_typography.dart';
import 'package:kseb/utils/app_spacing.dart';
import 'package:kseb/utils/app_decorations.dart';
import 'package:kseb/components/common/app_bar_builder.dart';
import 'package:kseb/components/common/app_button.dart';
import 'package:kseb/components/common/app_card.dart';
import 'package:kseb/components/common/app_text_field.dart';
import 'package:kseb/components/common/app_loading.dart';
import 'package:kseb/components/common/app_empty_state.dart';
import 'package:kseb/components/common/app_error_state.dart';
import 'package:kseb/components/common/app_scaffold.dart';

void main() {

  Widget createApp(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Quickstart validation — zero inline styling needed', () {
    testWidgets('builds a complete screen using only shared widgets & tokens',
        (tester) async {
      // This screen uses ONLY design system imports — no raw Colors.*,
      // no inline TextStyle constructors, no magic-number spacing.
      final screen = Scaffold(
        backgroundColor: AppColors.background,
        appBar: buildAppBar(title: 'Quickstart Screen'),
        body: AppPageWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Typography tokens
              Text('Page Title', style: AppTypography.headingStyle),
              SizedBox(height: AppSpacing.sm),
              Text('Subtitle text', style: AppTypography.captionStyle),
              SizedBox(height: AppSpacing.xl),

              // Card widget
              AppCard(
                accentColor: AppColors.primary,
                child: Column(
                  children: [
                    Text('Card Title', style: AppTypography.subheadingStyle),
                    SizedBox(height: AppSpacing.sm),
                    Text('Card body', style: AppTypography.bodyStyle),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Text field widget
              const AppTextField(
                label: 'Name',
                hintText: 'Enter your name',
              ),
              SizedBox(height: AppSpacing.lg),

              // Button variants
              AppButton(
                label: 'Primary Action',
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
              SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Outline Action',
                variant: AppButtonVariant.outline,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(createApp(screen));

      // Verify all widgets rendered
      expect(find.text('Quickstart Screen'), findsOneWidget);
      expect(find.text('Page Title'), findsOneWidget);
      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Primary Action'), findsOneWidget);
      expect(find.text('Outline Action'), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(AppTextField), findsOneWidget);
      expect(find.byType(AppButton), findsNWidgets(2));
      expect(find.byType(AppPageWrapper), findsOneWidget);
    });

    testWidgets('loading, error, and empty states render correctly',
        (tester) async {
      final screen = Scaffold(
        body: Column(
          children: [
            const AppLoading(message: 'Loading data...'),
            const AppEmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              subtitle: 'Add your first item',
            ),
            AppErrorState(
              message: 'Something went wrong',
              onRetry: () {},
            ),
          ],
        ),
      );

      await tester.pumpWidget(createApp(screen));

      expect(find.byType(AppLoading), findsOneWidget);
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Loading data...'), findsOneWidget);
      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('responsive extensions scale with screen size', (tester) async {
      late double padding360;
      late double padding600;

      // Test on small screen (360dp width, 640dp height)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(360, 640)),
          child: MaterialApp(
            home: Builder(builder: (context) {
              padding360 = context.responsivePadding(AppSpacing.xl);
              return const Scaffold(body: SizedBox());
            }),
          ),
        ),
      );

      // Test on large screen (600dp width, 900dp height)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, 900)),
          child: MaterialApp(
            home: Builder(builder: (context) {
              padding600 = context.responsivePadding(AppSpacing.xl);
              return const Scaffold(body: SizedBox());
            }),
          ),
        ),
      );

      // Small screen should have smaller padding than large screen
      expect(padding360, lessThan(padding600));
    });

    testWidgets('decoration tokens provide consistent card styling',
        (tester) async {
      final decoration = AppDecorations.modernCardDecoration;

      expect(decoration.color, equals(AppColors.surface));
      expect(decoration.borderRadius,
          equals(BorderRadius.circular(AppSpacing.radiusDefault)));
      expect(decoration.boxShadow, isNotNull);
    });
  });
}
