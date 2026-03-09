import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of auth events logged to the auth_events Firestore collection.
enum AuthEventType {
  loginSuccess,
  loginFailure,
  logout,
  idleTimeout,
  forceLogout;

  /// Firestore-stored string value (snake_case).
  String get firestoreValue {
    switch (this) {
      case AuthEventType.loginSuccess:
        return 'login_success';
      case AuthEventType.loginFailure:
        return 'login_failure';
      case AuthEventType.logout:
        return 'logout';
      case AuthEventType.idleTimeout:
        return 'idle_timeout';
      case AuthEventType.forceLogout:
        return 'force_logout';
    }
  }

  /// Parse a Firestore string value back to enum.
  static AuthEventType fromString(String value) {
    switch (value) {
      case 'login_success':
        return AuthEventType.loginSuccess;
      case 'login_failure':
        return AuthEventType.loginFailure;
      case 'logout':
        return AuthEventType.logout;
      case 'idle_timeout':
        return AuthEventType.idleTimeout;
      case 'force_logout':
        return AuthEventType.forceLogout;
      default:
        throw ArgumentError('Unknown AuthEventType: $value');
    }
  }
}

/// Represents an entry in the auth_events Firestore collection.
///
/// Events are immutable and append-only (FR-018, FR-019).
class AuthEventModel {
  final String? id;
  final String? userId;
  final String email;
  final AuthEventType eventType;
  final DateTime timestamp;
  final String? deviceInfo;
  final String? sessionToken;
  final Map<String, dynamic>? metadata;

  AuthEventModel({
    this.id,
    this.userId,
    required this.email,
    required this.eventType,
    required this.timestamp,
    this.deviceInfo,
    this.sessionToken,
    this.metadata,
  });

  /// Create from a Firestore document snapshot.
  factory AuthEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuthEventModel(
      id: doc.id,
      userId: data['userId'] as String?,
      email: data['email'] as String? ?? '',
      eventType: AuthEventType.fromString(data['eventType'] as String),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      deviceInfo: data['deviceInfo'] as String?,
      sessionToken: data['sessionToken'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create from a plain map (for testing or manual construction).
  factory AuthEventModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return AuthEventModel(
      id: id,
      userId: data['userId'] as String?,
      email: data['email'] as String? ?? '',
      eventType: AuthEventType.fromString(data['eventType'] as String),
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : data['timestamp'] as DateTime,
      deviceInfo: data['deviceInfo'] as String?,
      sessionToken: data['sessionToken'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore-compatible map.
  ///
  /// Uses [FieldValue.serverTimestamp] for the timestamp field to ensure
  /// the server sets the timestamp (required by security rules).
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'eventType': eventType.firestoreValue,
      'timestamp': FieldValue.serverTimestamp(),
      'deviceInfo': deviceInfo,
      'sessionToken': sessionToken,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Convert to a plain map with the actual DateTime (for testing).
  Map<String, dynamic> toTestMap() {
    return {
      'userId': userId,
      'email': email,
      'eventType': eventType.firestoreValue,
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceInfo': deviceInfo,
      'sessionToken': sessionToken,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
