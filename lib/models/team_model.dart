import 'package:cloud_firestore/cloud_firestore.dart';

/// Team model representing the hierarchical structure
class TeamModel {
  final String id;
  final String supervisorId;
  final String? managerId;
  final String areaCode;
  final List<String> members;
  final List<String> assets;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  TeamModel({
    required this.id,
    required this.supervisorId,
    this.managerId,
    required this.areaCode,
    this.members = const [],
    this.assets = const [],
    required this.createdAt,
    this.lastUpdated,
  });

  /// Create TeamModel from Firestore document
  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      supervisorId: data['supervisorId'] ?? '',
      managerId: data['managerId'],
      areaCode: data['areaCode'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      assets: List<String>.from(data['assets'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create TeamModel from map
  factory TeamModel.fromMap(Map<String, dynamic> data, String id) {
    return TeamModel(
      id: id,
      supervisorId: data['supervisorId'] ?? '',
      managerId: data['managerId'],
      areaCode: data['areaCode'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      assets: List<String>.from(data['assets'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert TeamModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'supervisorId': supervisorId,
      'managerId': managerId,
      'areaCode': areaCode,
      'members': members,
      'assets': assets,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  /// Copy with method
  TeamModel copyWith({
    String? id,
    String? supervisorId,
    String? managerId,
    String? areaCode,
    List<String>? members,
    List<String>? assets,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return TeamModel(
      id: id ?? this.id,
      supervisorId: supervisorId ?? this.supervisorId,
      managerId: managerId ?? this.managerId,
      areaCode: areaCode ?? this.areaCode,
      members: members ?? this.members,
      assets: assets ?? this.assets,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
