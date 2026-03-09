import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_event_model.dart';
import 'auth_audit_service.dart';
import 'session_service.dart';

/// Central orchestrator for all auth operations (FR-009).
///
/// Coordinates Firebase Auth, session management, and audit logging.
/// All auth-related actions (sign-in, sign-out, session validation)
/// should go through this service.
class AuthService {
  final FirebaseAuth _auth;
  final AuthAuditService _auditService;
  final SessionService _sessionService;

  /// In-memory session token for the current login (per research R2 note 5).
  String? _localSessionToken;

  AuthService({
    FirebaseAuth? auth,
    AuthAuditService? auditService,
    SessionService? sessionService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _auditService = auditService ?? AuthAuditService(),
        _sessionService = sessionService ?? SessionService();

  /// Reactive auth state stream — drives the AuthGate navigation.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user (null if not authenticated).
  User? get currentUser => _auth.currentUser;

  /// In-memory session token (null if no active session).
  String? get localSessionToken => _localSessionToken;

  /// Sign in with email and password.
  ///
  /// On success:
  /// 1. Creates a session token in Firestore
  /// 2. Logs a `login_success` audit event
  ///
  /// On failure:
  /// 1. Logs a `login_failure` audit event
  /// 2. Rethrows the exception for the UI to handle
  Future<UserCredential> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        // Create session token
        _localSessionToken = await _sessionService.createSession(user.uid);

        // Log success
        await _auditService.logEvent(
          eventType: AuthEventType.loginSuccess,
          email: email.trim(),
          userId: user.uid,
          sessionToken: _localSessionToken,
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      // Log failure
      await _auditService.logEvent(
        eventType: AuthEventType.loginFailure,
        email: email.trim(),
        metadata: {'errorCode': e.code, 'message': e.message},
      );
      rethrow;
    } catch (e) {
      // Log unexpected failure
      await _auditService.logEvent(
        eventType: AuthEventType.loginFailure,
        email: email.trim(),
        metadata: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Sign out the current user.
  ///
  /// [reason] describes why the sign-out occurred:
  /// - `'manual'` — user pressed logout
  /// - `'idle_timeout'` — inactivity timeout
  /// - `'force_logout'` — session invalidated by another device
  Future<void> signOut({String reason = 'manual'}) async {
    final user = _auth.currentUser;
    final email = user?.email ?? 'unknown';
    final userId = user?.uid;
    final sessionToken = _localSessionToken;

    // Determine event type based on reason
    AuthEventType eventType;
    switch (reason) {
      case 'idle_timeout':
        eventType = AuthEventType.idleTimeout;
        break;
      case 'force_logout':
        eventType = AuthEventType.forceLogout;
        break;
      default:
        eventType = AuthEventType.logout;
    }

    // Clear session in Firestore
    if (userId != null) {
      await _sessionService.clearSession(userId);
    }

    // Clear local token
    _localSessionToken = null;

    // Sign out from Firebase
    await _auth.signOut();

    // Log the event (after signOut so it doesn't block the UX)
    await _auditService.logEvent(
      eventType: eventType,
      email: email,
      userId: userId,
      sessionToken: sessionToken,
      metadata: {'reason': reason},
    );
  }

  /// Validate the current session against Firestore.
  ///
  /// Returns `true` if the session is valid, `false` if another device
  /// has logged in (token mismatch). Returns `true` on network error
  /// (graceful degradation).
  Future<bool> validateSession() async {
    final user = _auth.currentUser;
    if (user == null || _localSessionToken == null) return false;

    return _sessionService.isSessionValid(user.uid, _localSessionToken!);
  }

  /// Read the idle timeout configuration from Firestore.
  ///
  /// Returns the timeout in minutes. Defaults to 15 if the document
  /// doesn't exist or there's an error.
  Future<int> getIdleTimeoutMinutes() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('auth')
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['idleTimeoutMinutes'] as int? ?? 15;
      }
    } catch (e) {
      debugPrint('AuthService: Failed to read idle timeout config: $e');
    }
    return 15;
  }
}
