import 'package:cloud_firestore/cloud_firestore.dart';

/// User roles in the KSEB system
enum UserRole {
  staff,
  supervisor,
  manager,
  coo,
  director;

  String get displayName {
    switch (this) {
      case UserRole.staff:
        return 'Staff';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.manager:
        return 'Manager';
      case UserRole.coo:
        return 'COO';
      case UserRole.director:
        return 'Director';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'staff':
        return UserRole.staff;
      case 'supervisor':
        return UserRole.supervisor;
      case 'manager':
        return UserRole.manager;
      case 'coo':
        return UserRole.coo;
      case 'director':
        return UserRole.director;
      default:
        return UserRole.staff;
    }
  }

  /// Get the hierarchy level of a role (lower number = higher authority)
  int get hierarchyLevel {
    switch (this) {
      case UserRole.director:
        return 0;
      case UserRole.coo:
        return 1;
      case UserRole.manager:
        return 2;
      case UserRole.supervisor:
        return 3;
      case UserRole.staff:
        return 4;
    }
  }

  /// Check if this role can manage another role
  bool canManage(UserRole otherRole) {
    return hierarchyLevel <= otherRole.hierarchyLevel;
  }

  /// Get all roles that this role can assign/manage
  List<UserRole> get manageableRoles {
    return UserRole.values
        .where((role) => hierarchyLevel <= role.hierarchyLevel)
        .toList();
  }

  /// Check if this role is supervisor or higher
  bool get isSupervisor {
    return this == UserRole.supervisor ||
        this == UserRole.manager ||
        this == UserRole.coo ||
        this == UserRole.director;
  }
}

/// User model representing a user in the KSEB system
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? teamId;
  final String? areaCode;
  final String? photoUrl;
  final String? insuranceId;
  final int bonusPoints;
  final double bonusAmount;
  final DateTime? dob;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.teamId,
    this.areaCode,
    this.photoUrl,
    this.insuranceId,
    this.bonusPoints = 0,
    this.bonusAmount = 0.0,
    this.dob,
    required this.createdAt,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'staff'),
      teamId: data['teamId'],
      areaCode: data['areaCode'],
      photoUrl: data['photoUrl'],
      insuranceId: data['insuranceId'],
      bonusPoints: data['bonusPoints'] ?? 0,
      bonusAmount: (data['bonusAmount'] ?? 0).toDouble(),
      dob: data['dob'] != null ? (data['dob'] as Timestamp).toDate() : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Create UserModel from map (for query results)
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'staff'),
      teamId: data['teamId'],
      areaCode: data['areaCode'],
      photoUrl: data['photoUrl'],
      insuranceId: data['insuranceId'],
      bonusPoints: data['bonusPoints'] ?? 0,
      bonusAmount: (data['bonusAmount'] ?? 0).toDouble(),
      dob: data['dob'] != null ? (data['dob'] as Timestamp).toDate() : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert UserModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'teamId': teamId,
      'areaCode': areaCode,
      'photoUrl': photoUrl,
      'insuranceId': insuranceId,
      'bonusPoints': bonusPoints,
      'bonusAmount': bonusAmount,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Check if user is a supervisor or higher
  bool get isSupervisor {
    return role == UserRole.supervisor ||
        role == UserRole.manager ||
        role == UserRole.coo ||
        role == UserRole.director;
  }

  /// Check if user is a manager or higher
  bool get isManager {
    return role == UserRole.manager ||
        role == UserRole.coo ||
        role == UserRole.director;
  }

  /// Check if user is COO or Director
  bool get isExecutive {
    return role == UserRole.coo || role == UserRole.director;
  }

  /// Check if user is Director
  bool get isDirector {
    return role == UserRole.director;
  }

  /// Check if current user can edit another user based on role hierarchy
  bool canEdit(UserRole otherUserRole) {
    return role.canManage(otherUserRole);
  }

  /// Copy with method for creating modified copies
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? teamId,
    String? areaCode,
    String? photoUrl,
    String? insuranceId,
    int? bonusPoints,
    double? bonusAmount,
    DateTime? dob,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      areaCode: areaCode ?? this.areaCode,
      photoUrl: photoUrl ?? this.photoUrl,
      insuranceId: insuranceId ?? this.insuranceId,
      bonusPoints: bonusPoints ?? this.bonusPoints,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      dob: dob ?? this.dob,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
