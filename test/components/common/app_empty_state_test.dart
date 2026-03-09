import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kseb/components/common/app_empty_state.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppEmptyState', () {
    testWidgets('renders icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No records',
            subtitle: 'Check back later',
          ),
        ),
      ));

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('No records'), findsOneWidget);
      expect(find.text('Check back later'), findsOneWidget);
    });

    testWidgets('renders without subtitle when not provided', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No records',
          ),
        ),
      ));

      expect(find.text('No records'), findsOneWidget);
    });

    testWidgets('renders action button when actionLabel and onAction provided',
        (tester) async {
      var actionCalled = false;
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No records',
            actionLabel: 'Refresh',
            onAction: () => actionCalled = true,
          ),
        ),
      ));

      expect(find.text('Refresh'), findsOneWidget);
      await tester.tap(find.text('Refresh'));
      expect(actionCalled, isTrue);
    });

    testWidgets('does not show action button when actionLabel is null',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No records',
          ),
        ),
      ));

      // Should not have any button
      expect(find.text('Refresh'), findsNothing);
    });

    testWidgets('icon has correct size (64dp)', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No records',
          ),
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
      expect(icon.size, 64);
    });
  });
}
