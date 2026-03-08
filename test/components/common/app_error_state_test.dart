import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kseb/components/common/app_error_state.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppErrorState', () {
    testWidgets('renders error icon and message', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppErrorState(message: 'Something went wrong'),
        ),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry provided', (tester) async {
      var retryCalled = false;
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppErrorState(
            message: 'Failed to load',
            onRetry: () => retryCalled = true,
          ),
        ),
      ));

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retryCalled, isTrue);
    });

    testWidgets('does not show retry button when onRetry is null',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppErrorState(message: 'Error'),
        ),
      ));

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('uses custom icon when provided', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppErrorState(
            message: 'Not found',
            icon: Icons.cloud_off,
          ),
        ),
      ));

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('error icon has correct size (56dp)', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppErrorState(message: 'Error'),
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.size, 56);
    });
  });
}
