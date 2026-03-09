import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kseb/screens/login_screen.dart';
import 'package:kseb/services/auth_service.dart';
import 'package:kseb/services/auth_audit_service.dart';
import 'package:kseb/services/session_service.dart';
import 'package:kseb/components/common/password_strength_indicator.dart';
import '../helpers/test_helpers.dart';
import '../helpers/firebase_mock_helper.dart';

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    setupTestEnvironment();
    await Firebase.initializeApp();
  });

  /// Create an AuthService with fake Firestore (avoids real network).
  AuthService createTestAuthService() {
    final fakeFirestore = FakeFirebaseFirestore();
    return AuthService(
      auditService: AuthAuditService(firestore: fakeFirestore),
      sessionService: SessionService(firestore: fakeFirestore),
    );
  }

  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          LoginScreen(authService: createTestAuthService()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders KSEB header and subtitle', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          LoginScreen(authService: createTestAuthService()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KSEB'), findsOneWidget);
      expect(find.text('Worker Portal'), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('renders SIGN IN button', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          LoginScreen(authService: createTestAuthService()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SIGN IN'), findsOneWidget);
    });

    testWidgets('renders footer links', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          LoginScreen(authService: createTestAuthService()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('renders bolt icon', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          LoginScreen(authService: createTestAuthService()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    });

    testWidgets('shows password strength indicator when typing',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          LoginScreen(authService: createTestAuthService()),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no strength indicator visible (empty password)
      expect(find.byType(PasswordStrengthIndicator), findsOneWidget);
      // The indicator shows SizedBox.shrink for empty password,
      // so no strength labels should be visible
      expect(find.text('Weak'), findsNothing);
      expect(find.text('Fair'), findsNothing);
      expect(find.text('Strong'), findsNothing);

      // Type in the password field
      final passwordField = find.widgetWithText(TextField, 'Password');
      await tester.enterText(passwordField, 'abc');
      await tester.pumpAndSettle();

      // Now strength indicator should show "Weak"
      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('shows Fair for medium-strength password', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          LoginScreen(authService: createTestAuthService()),
        ),
      );
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextField, 'Password');
      // "Abcdefghij": >= 6 (+1), >= 10 (+1), upper (+1), lower (+1) = 4 → Fair
      await tester.enterText(passwordField, 'Abcdefghij');
      await tester.pumpAndSettle();

      expect(find.text('Fair'), findsOneWidget);
    });

    testWidgets('shows Strong for complex password', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          LoginScreen(authService: createTestAuthService()),
        ),
      );
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextField, 'Password');
      // "MyP@ss1": >= 6 (+1), upper (+1), lower (+1), digit (+1), special (+1) = 5 → Strong
      await tester.enterText(passwordField, 'MyP@ss1');
      await tester.pumpAndSettle();

      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('no cooldown notice initially', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          LoginScreen(authService: createTestAuthService()),
        ),
      );
      await tester.pumpAndSettle();

      // Should not show cooldown timer
      expect(find.byIcon(Icons.timer_outlined), findsNothing);
      expect(find.textContaining('Try again in'), findsNothing);
    });

    testWidgets('icon animation completes', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          LoginScreen(authService: createTestAuthService()),
        ),
      );
      // Let animation complete
      await tester.pumpAndSettle();

      // Icon should be rendered and visible after animation
      final icon = find.byIcon(Icons.bolt_rounded);
      expect(icon, findsOneWidget);
    });

    testWidgets('icon animation skips when reduce-motion enabled',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: LoginScreen(authService: createTestAuthService()),
          ),
        ),
      );
      // Single pump — animation should jump to end immediately
      await tester.pump();

      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    });
  });
}
