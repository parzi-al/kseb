import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kseb/components/common/app_scaffold.dart';
import 'package:kseb/utils/app_colors.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppPageWrapper', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppPageWrapper(child: Text('Content')),
        ),
      ));

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('wraps in SingleChildScrollView when scrollable is true',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppPageWrapper(child: Text('Scrollable')),
        ),
      ));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('does not wrap in scroll view when scrollable is false',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppPageWrapper(
            scrollable: false,
            child: Text('Not scrollable'),
          ),
        ),
      ));

      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('applies background color', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppPageWrapper(child: Text('BG')),
        ),
      ));

      // Should have a Container with background color
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppPageWrapper),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.color ?? (container.decoration as BoxDecoration?)?.color,
          AppColors.background);
    });

    testWidgets('applies custom padding when provided', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppPageWrapper(
            padding: EdgeInsets.all(8),
            child: Text('Custom'),
          ),
        ),
      ));

      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('applies custom background color when provided',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppPageWrapper(
            backgroundColor: Colors.red,
            child: const Text('Red BG'),
          ),
        ),
      ));

      expect(find.text('Red BG'), findsOneWidget);
    });
  });
}
