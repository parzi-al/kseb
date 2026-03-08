import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kseb/components/common/app_text_field.dart';
import 'package:kseb/utils/app_colors.dart';
import 'package:kseb/utils/app_spacing.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppTextField', () {
    testWidgets('renders with label text', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(body: AppTextField(label: 'Name')),
      ));

      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('renders hint text', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppTextField(label: 'Name', hintText: 'Enter name'),
        ),
      ));

      expect(find.text('Enter name'), findsOneWidget);
    });

    testWidgets('displays error text', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppTextField(label: 'Name', errorText: 'Required'),
        ),
      ));

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('uses TextFormField', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(body: AppTextField(label: 'Name')),
      ));

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppTextField(label: 'Name', controller: controller),
        ),
      ));

      await tester.enterText(find.byType(TextFormField), 'John');
      expect(controller.text, 'John');
    });

    testWidgets('triggers onChanged callback', (tester) async {
      String? changedValue;
      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: AppTextField(
            label: 'Name',
            onChanged: (v) => changedValue = v,
          ),
        ),
      ));

      await tester.enterText(find.byType(TextFormField), 'Jane');
      expect(changedValue, 'Jane');
    });

    testWidgets('renders prefix and suffix icons', (tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          body: AppTextField(
            label: 'Search',
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.clear),
          ),
        ),
      ));

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });
  });
}
