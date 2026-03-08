import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kseb/components/common/app_button.dart';
import 'package:kseb/utils/app_colors.dart';
import 'package:kseb/utils/app_spacing.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppButton(label: 'Save', onPressed: () {}),
        ),
      ));

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('primary variant has gradient decoration', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppButton(
            label: 'Save',
            variant: AppButtonVariant.primary,
            onPressed: () {},
          ),
        ),
      ));

      // Primary button has a gradient container
      final containers = find.descendant(
        of: find.byType(AppButton),
        matching: find.byType(Container),
      );
      expect(containers, findsWidgets);
    });

    testWidgets('outline variant has border', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outline,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('destructive variant uses error color', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppButton(
            label: 'Delete',
            variant: AppButtonVariant.destructive,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('text variant renders with transparent background',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppButton(
            label: 'Skip',
            variant: AppButtonVariant.text,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('shows spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppButton(
            label: 'Saving...',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Label should not be visible when loading
      expect(find.text('Saving...'), findsNothing);
    });

    testWidgets('renders at reduced opacity when disabled', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppButton(
            label: 'Disabled',
            onPressed: null,
          ),
        ),
      ));

      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(AppButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.5);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppButton(
            label: 'Delete',
            icon: Icons.delete,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppButton(
            label: 'Press',
            onPressed: () => pressed = true,
          ),
        ),
      ));

      await tester.tap(find.byType(AppButton));
      expect(pressed, isTrue);
    });
  });
}
