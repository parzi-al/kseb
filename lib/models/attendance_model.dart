import 'package:cloud_firestore/cloud_firestore.dart';

/// Valid attendance status values.
const Set<String> _validStatuses = {'present', 'absent', 'leave'};

/// Normalise a [DateTime] to midnight (year, month, day only).
DateTime _normaliseToMidnight(DateTime dt) =>
    DateTime(dt.year, dt.month, dt.day);

DateTime _dateOnlyFromValue(dynamic value) {
  if (value == null) return DateTime.now();

  if (value is Timestamp) {
    final localDate = value.toDate().toLocal();
    final dateSafeValue = localDate.add(const Duration(hours: 12));
    return _normaliseToMidnight(dateSafeValue);
  }

  if (value is DateTime) {
    return _normaliseToMidnight(value);
  }

  return _normaliseToMidnight(DateTime.parse(value.toString()));
}

DateTime _dateTimeFromValue(dynamic value) {
  if (value == null) return DateTime.now();

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.parse(value.toString());
}

/// Attendance model for the new structure.
///
/// Single data contract used by [AttendanceService], screens, and tests.
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
    required DateTime date,
    this.verifiedBy,
    this.status = 'present',
    required this.timestamp,
  }) : date = _normaliseToMidnight(date) {
    if (!_validStatuses.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Must be one of: ${_validStatuses.join(', ')}',
      );
    }
  }

  /// Create AttendanceModel from Firestore document.
  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      worksheetId: data['worksheetId'],
      date: _dateOnlyFromValue(data['date']),
      verifiedBy: data['verifiedBy'],
      status: data['status'] ?? 'present',
      timestamp: _dateTimeFromValue(data['timestamp']),
    );
  }

  /// Create AttendanceModel from map.
  factory AttendanceModel.fromMap(Map<String, dynamic> data, String id) {
    return AttendanceModel(
      id: id,
      userId: data['userId'] ?? '',
      worksheetId: data['worksheetId'],
      date: _dateOnlyFromValue(data['date']),
      verifiedBy: data['verifiedBy'],
      status: data['status'] ?? 'present',
      timestamp: _dateTimeFromValue(data['timestamp']),
    );
  }

  /// Convert AttendanceModel to map for Firestore.
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
