import 'package:cloud_firestore/cloud_firestore.dart';

/// Team model representing the hierarchical structure
class TeamModel {
  final String id;
  final String name;
  final String supervisorId;
  final String? managerId;
  final String areaCode;
  final List<String> members;
  final List<String> assets;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime? lastUpdated;
  final String? lastUpdatedBy;

  TeamModel({
    required this.id,
    required this.name,
    required this.supervisorId,
    this.managerId,
    required this.areaCode,
    this.members = const [],
    this.assets = const [],
    required this.createdAt,
    this.createdBy,
    this.lastUpdated,
    this.lastUpdatedBy,
  });

  /// Create TeamModel from Firestore document
  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Team',
      supervisorId: data['supervisorId'] ?? '',
      managerId: data['managerId'],
      areaCode: data['areaCode'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      assets: List<String>.from(data['assets'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['createdBy'],
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      lastUpdatedBy: data['lastUpdatedBy'],
    );
  }

  /// Create TeamModel from map
  factory TeamModel.fromMap(Map<String, dynamic> data, String id) {
    return TeamModel(
      id: id,
      name: data['name'] ?? 'Unnamed Team',
      supervisorId: data['supervisorId'] ?? '',
      managerId: data['managerId'],
      areaCode: data['areaCode'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      assets: List<String>.from(data['assets'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['createdBy'],
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      lastUpdatedBy: data['lastUpdatedBy'],
    );
  }

  /// Convert TeamModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'supervisorId': supervisorId,
      'managerId': managerId,
      'areaCode': areaCode,
      'members': members,
      'assets': assets,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'lastUpdatedBy': lastUpdatedBy,
    };
  }

  /// Copy with method
  TeamModel copyWith({
    String? id,
    String? name,
    String? supervisorId,
    String? managerId,
    String? areaCode,
    List<String>? members,
    List<String>? assets,
    DateTime? createdAt,
    String? createdBy,
    DateTime? lastUpdated,
    String? lastUpdatedBy,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      supervisorId: supervisorId ?? this.supervisorId,
      managerId: managerId ?? this.managerId,
      areaCode: areaCode ?? this.areaCode,
      members: members ?? this.members,
      assets: assets ?? this.assets,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
    );
  }
}
