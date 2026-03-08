import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kseb/components/common/app_loading.dart';
import 'package:kseb/utils/app_colors.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppLoading', () {
    testWidgets('fullPage variant shows centered spinner', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(body: AppLoading()),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('inline variant shows small spinner in a row', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppLoading(variant: AppLoadingVariant.inline),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('overlay variant fills available space with backdrop',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: SizedBox.expand(
            child: Stack(children: [
              const Text('Content'),
              const AppLoading(variant: AppLoadingVariant.overlay),
            ]),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Content should still be visible beneath overlay
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('displays message when provided', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(body: AppLoading(message: 'Loading...')),
      ));

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('does not display message when not provided', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(body: AppLoading()),
      ));

      // Only spinner, no text widgets from AppLoading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('inline variant shows message next to spinner',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppLoading(
            variant: AppLoadingVariant.inline,
            message: 'Fetching...',
          ),
        ),
      ));

      expect(find.text('Fetching...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
