import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Manages single-session enforcement via Firestore (FR-020, FR-021, FR-022).
///
/// Stores the active session token on the user's document (`users/{uid}`).
/// On login, a new token is generated and written. On app resume, the local
/// token is compared to the Firestore token — mismatch means force-logout.
class SessionService {
  final FirebaseFirestore _firestore;

  SessionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generate a session token.
  ///
  /// Not cryptographically sensitive — used only for session correlation.
  /// Format: `sess_{timestamp}_{random}`.
  String _generateToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure().nextInt(999999).toString().padLeft(6, '0');
    return 'sess_${timestamp}_$random';
  }

  /// Create a new session for the user.
  ///
  /// Writes [activeSessionToken] and [lastLoginAt] to the user's document.
  /// Returns the generated session token for local storage.
  Future<String> createSession(String userId) async {
    final token = _generateToken();
    try {
      await _firestore.collection('users').doc(userId).update({
        'activeSessionToken': token,
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('SessionService: Failed to create session: $e');
      // Still return the token — we can retry later
    }
    return token;
  }

  /// Clear the session for the user (on logout).
  ///
  /// Sets [activeSessionToken] to null.
  Future<void> clearSession(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'activeSessionToken': null,
      });
    } catch (e) {
      debugPrint('SessionService: Failed to clear session: $e');
    }
  }

  /// Check if the local session token matches the one stored in Firestore.
  ///
  /// Returns `true` if the session is valid (tokens match), `false` if
  /// another device has logged in (tokens differ).
  ///
  /// Returns `true` on error (network failure) to gracefully degrade —
  /// don't force-logout on connectivity issues (research R2 note 3).
  Future<bool> isSessionValid(String userId, String localToken) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final storedToken = data['activeSessionToken'] as String?;
      return storedToken == localToken;
    } catch (e) {
      // Graceful degradation on network failure
      debugPrint('SessionService: Failed to validate session: $e');
      return true;
    }
  }
}
