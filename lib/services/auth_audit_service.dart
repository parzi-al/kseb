import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_event_model.dart';

/// Writes auth events to the Firestore `auth_events` collection (FR-018, FR-019).
///
/// Events are append-only — no updates or deletes.
class AuthAuditService {
  final FirebaseFirestore _firestore;

  AuthAuditService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Log an auth event to Firestore.
  ///
  /// The [email] is always required. [userId] may be null for failed logins
  /// where the user is unknown. [sessionToken] correlates events to sessions.
  Future<void> logEvent({
    required AuthEventType eventType,
    required String email,
    String? userId,
    String? sessionToken,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final event = AuthEventModel(
        userId: userId,
        email: email,
        eventType: eventType,
        timestamp: DateTime.now(), // Server timestamp used in toMap()
        sessionToken: sessionToken,
        metadata: metadata,
      );

      await _firestore.collection('auth_events').add(event.toMap());
    } catch (e) {
      // Audit logging should never block the auth flow.
      // Log the error but don't rethrow.
      debugPrint('AuthAuditService: Failed to log event: $e');
    }
  }

  /// Read auth events for a specific user (admin use).
  ///
  /// Returns events ordered by timestamp descending. Limited to [limit] results.
  Future<List<AuthEventModel>> getEventsForUser(
    String userId, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('auth_events')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => AuthEventModel.fromFirestore(doc))
        .toList();
  }

  /// Read recent auth events across all users (admin use).
  ///
  /// Returns events ordered by timestamp descending. Limited to [limit] results.
  Future<List<AuthEventModel>> getRecentEvents({int limit = 100}) async {
    final snapshot = await _firestore
        .collection('auth_events')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => AuthEventModel.fromFirestore(doc))
        .toList();
  }
}
