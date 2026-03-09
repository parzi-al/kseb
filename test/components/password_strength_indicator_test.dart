import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/components/common/password_strength_indicator.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('PasswordStrengthIndicator', () {
    group('calculateScore', () {
      test('empty password returns 0', () {
        expect(PasswordStrengthIndicator.calculateScore(''), 0);
      });

      test('short lowercase only = 0 (less than 6 chars)', () {
        expect(PasswordStrengthIndicator.calculateScore('abc'), 1); // lowercase only
      });

      test('6 chars all lowercase = 2 (Weak)', () {
        // length >= 6 (+1) + lowercase (+1) = 2
        expect(PasswordStrengthIndicator.calculateScore('abcdef'), 2);
      });

      test('mixed-complexity 6 chars = 5 (Strong)', () {
        // "Aa1!bc": length >= 6 (+1) + upper (+1) + lower (+1) + digit (+1) + special (+1) = 5
        expect(PasswordStrengthIndicator.calculateScore('Aa1!bc'), 5);
      });

      test('10 chars all lowercase = 3 (Fair)', () {
        // length >= 6 (+1) + length >= 10 (+1) + lowercase (+1) = 3
        expect(PasswordStrengthIndicator.calculateScore('abcdefghij'), 3);
      });

      test('full complexity 10+ chars = 6 (Strong)', () {
        // "MyP@ssw0rd123": length >= 6 (+1) + length >= 10 (+1) + upper (+1)
        // + lower (+1) + digit (+1) + special (+1) = 6
        expect(PasswordStrengthIndicator.calculateScore('MyP@ssw0rd123'), 6);
      });

      test('digits only 6 chars = 2 (Weak)', () {
        // length >= 6 (+1) + digit (+1) = 2
        expect(PasswordStrengthIndicator.calculateScore('123456'), 2);
      });

      test('special chars detect various symbols', () {
        // Each should trigger the special char criterion
        for (final char in ['!', '@', '#', '\$', '%', '^', '&', '*']) {
          expect(
            PasswordStrengthIndicator.calculateScore('a$char'),
            greaterThanOrEqualTo(2), // lowercase + special at minimum
          );
        }
      });
    });

    group('getStrength', () {
      test('score 0 = Weak', () {
        expect(PasswordStrengthIndicator.getStrength(0), PasswordStrength.weak);
      });

      test('score 2 = Weak', () {
        expect(PasswordStrengthIndicator.getStrength(2), PasswordStrength.weak);
      });

      test('score 3 = Fair', () {
        expect(PasswordStrengthIndicator.getStrength(3), PasswordStrength.fair);
      });

      test('score 4 = Fair', () {
        expect(PasswordStrengthIndicator.getStrength(4), PasswordStrength.fair);
      });

      test('score 5 = Strong', () {
        expect(
            PasswordStrengthIndicator.getStrength(5), PasswordStrength.strong);
      });

      test('score 6 = Strong', () {
        expect(
            PasswordStrengthIndicator.getStrength(6), PasswordStrength.strong);
      });
    });

    group('widget', () {
      testWidgets('shows nothing when password is empty', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const Scaffold(
              body: PasswordStrengthIndicator(password: ''),
            ),
          ),
        );

        // SizedBox.shrink renders nothing
        expect(find.text('Weak'), findsNothing);
        expect(find.text('Fair'), findsNothing);
        expect(find.text('Strong'), findsNothing);
      });

      testWidgets('shows Weak for simple password', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const Scaffold(
              body: PasswordStrengthIndicator(password: 'abcdef'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Weak'), findsOneWidget);
      });

      testWidgets('shows Fair for medium password', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const Scaffold(
              body: PasswordStrengthIndicator(password: 'Abcdefghij'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // "Abcdefghij": >= 6 (+1), >= 10 (+1), upper (+1), lower (+1) = 4 → Fair
        expect(find.text('Fair'), findsOneWidget);
      });

      testWidgets('shows Strong for complex password', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const Scaffold(
              body: PasswordStrengthIndicator(password: 'MyP@ss1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // "MyP@ss1": >= 6 (+1), upper (+1), lower (+1), digit (+1), special (+1) = 5 → Strong
        expect(find.text('Strong'), findsOneWidget);
      });

      testWidgets('has accessibility semantics', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const Scaffold(
              body: PasswordStrengthIndicator(password: 'abc'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The Semantics widget should contain the strength label
        final semantics =
            tester.getSemantics(find.byType(PasswordStrengthIndicator));
        expect(semantics.label, contains('Password strength: Weak'));
      });
    });
  });
}
