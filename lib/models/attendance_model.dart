import 'package:cloud_firestore/cloud_firestore.dart';

/// Attendance model for the new structure
class AttendanceModel {
  final String id;
  final String userId;
  final String? worksheetId;
  final DateTime date;
  final String? verifiedBy;
  final String status;
  final DateTime timestamp;

  AttendanceModel({
    required this.id,
    required this.userId,
    this.worksheetId,
    required this.date,
    this.verifiedBy,
    this.status = 'present',
    required this.timestamp,
  });

  /// Create AttendanceModel from Firestore document
  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      worksheetId: data['worksheetId'],
      date: data['date'] != null
          ? (data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.parse(data['date']))
          : DateTime.now(),
      verifiedBy: data['verifiedBy'],
      status: data['status'] ?? 'present',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Create AttendanceModel from map
  factory AttendanceModel.fromMap(Map<String, dynamic> data, String id) {
    return AttendanceModel(
      id: id,
      userId: data['userId'] ?? '',
      worksheetId: data['worksheetId'],
      date: data['date'] != null
          ? (data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.parse(data['date']))
          : DateTime.now(),
      verifiedBy: data['verifiedBy'],
      status: data['status'] ?? 'present',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert AttendanceModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'worksheetId': worksheetId,
      'date': Timestamp.fromDate(date),
      'verifiedBy': verifiedBy,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
