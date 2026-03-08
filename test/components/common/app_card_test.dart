import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kseb/components/common/app_card.dart';
import 'package:kseb/utils/app_colors.dart';
import 'package:kseb/utils/app_spacing.dart';
import 'package:kseb/utils/app_decorations.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(body: AppCard(child: Text('Hello'))),
      ));

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('applies default modernCardDecoration', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(body: AppCard(child: Text('Hello'))),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppCard),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.surface);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(AppSpacing.radiusDefault),
      );
    });

    testWidgets('applies accent border when accentColor provided',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppCard(
            accentColor: Colors.blue,
            child: Text('Accent'),
          ),
        ),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppCard),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('wraps in InkWell when onTap provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppCard(
            onTap: () => tapped = true,
            child: const Text('Tap me'),
          ),
        ),
      ));

      expect(find.byType(InkWell), findsOneWidget);
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('does not show InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(body: AppCard(child: Text('No tap'))),
      ));

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('uses custom padding when provided', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppCard(
            padding: EdgeInsets.all(32),
            child: Text('Custom padding'),
          ),
        ),
      ));

      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.text('Custom padding'),
          matching: find.byType(Padding),
        ).first,
      );
      expect(padding.padding, const EdgeInsets.all(32));
    });
  });
}
