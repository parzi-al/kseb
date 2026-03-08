import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kseb/components/common/app_bar_builder.dart';
import 'package:kseb/utils/app_colors.dart';
import 'package:kseb/utils/app_typography.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('buildAppBar', () {
    testWidgets('renders with correct background and foreground colors',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          appBar: buildAppBar(title: 'Test'),
          body: const SizedBox(),
        ),
      ));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppColors.surface);
      expect(appBar.foregroundColor, AppColors.textPrimary);
    });

    testWidgets('renders with correct elevation', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          appBar: buildAppBar(title: 'Test'),
          body: const SizedBox(),
        ),
      ));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.elevation, 0.5);
    });

    testWidgets('renders with transparent surfaceTintColor', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          appBar: buildAppBar(title: 'Test'),
          body: const SizedBox(),
        ),
      ));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.surfaceTintColor, Colors.transparent);
    });

    testWidgets('uses headingStyle for title text style', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          appBar: buildAppBar(title: 'Test'),
          body: const SizedBox(),
        ),
      ));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(
          appBar.titleTextStyle?.fontSize, AppTypography.headingStyle.fontSize);
      expect(appBar.titleTextStyle?.fontWeight,
          AppTypography.headingStyle.fontWeight);
    });

    testWidgets('centers title by default', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          appBar: buildAppBar(title: 'Test'),
          body: const SizedBox(),
        ),
      ));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, true);
    });

    testWidgets('renders actions when provided', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          appBar: buildAppBar(
            title: 'Test',
            actions: [const Icon(Icons.settings)],
          ),
          body: const SizedBox(),
        ),
      ));

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          appBar: buildAppBar(title: 'My Title'),
          body: const SizedBox(),
        ),
      ));

      expect(find.text('My Title'), findsOneWidget);
    });
  });
}
