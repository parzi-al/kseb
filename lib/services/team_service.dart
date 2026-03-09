import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';

/// Service for managing teams in the hierarchical structure
class TeamService {
  static const String _teamsCollection = 'teams';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get team by ID
  Future<TeamModel?> getTeamById(String teamId) async {
    try {
      final doc =
          await _firestore.collection(_teamsCollection).doc(teamId).get();

      if (!doc.exists) {
        return null;
      }

      return TeamModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting team by ID: $e');
      return null;
    }
  }

  /// Get team stream by ID
  Stream<TeamModel?> getTeamStream(String teamId) {
    return _firestore
        .collection(_teamsCollection)
        .doc(teamId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return TeamModel.fromFirestore(doc);
    });
  }

  /// Get teams by supervisor ID
  Stream<List<TeamModel>> getTeamsBySupervisor(String supervisorId) {
    return _firestore
        .collection(_teamsCollection)
        .where('supervisorId', isEqualTo: supervisorId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TeamModel.fromFirestore(doc)).toList());
  }

  /// Get teams by manager ID
  Stream<List<TeamModel>> getTeamsByManager(String managerId) {
    return _firestore
        .collection(_teamsCollection)
        .where('managerId', isEqualTo: managerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TeamModel.fromFirestore(doc)).toList());
  }

  /// Get teams by area code
  Stream<List<TeamModel>> getTeamsByAreaCode(String areaCode) {
    return _firestore
        .collection(_teamsCollection)
        .where('areaCode', isEqualTo: areaCode)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TeamModel.fromFirestore(doc)).toList());
  }

  /// Create a new team
  Future<String> createTeam(TeamModel team) async {
    try {
      final docRef =
          await _firestore.collection(_teamsCollection).add(team.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating team: $e');
      rethrow;
    }
  }

  /// Update an existing team
  Future<void> updateTeam(String teamId, Map<String, dynamic> updates) async {
    try {
      updates['lastUpdated'] = FieldValue.serverTimestamp();
      await _firestore.collection(_teamsCollection).doc(teamId).update(updates);
    } catch (e) {
      print('Error updating team: $e');
      rethrow;
    }
  }

  /// Add member to team
  Future<void> addMemberToTeam(String teamId, String userId) async {
    try {
      await _firestore.collection(_teamsCollection).doc(teamId).update({
        'members': FieldValue.arrayUnion([userId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding member to team: $e');
      rethrow;
    }
  }

  /// Remove member from team
  Future<void> removeMemberFromTeam(String teamId, String userId) async {
    try {
      await _firestore.collection(_teamsCollection).doc(teamId).update({
        'members': FieldValue.arrayRemove([userId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing member from team: $e');
      rethrow;
    }
  }

  /// Add asset to team
  Future<void> addAssetToTeam(String teamId, String assetId) async {
    try {
      await _firestore.collection(_teamsCollection).doc(teamId).update({
        'assets': FieldValue.arrayUnion([assetId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding asset to team: $e');
      rethrow;
    }
  }

  /// Remove asset from team
  Future<void> removeAssetFromTeam(String teamId, String assetId) async {
    try {
      await _firestore.collection(_teamsCollection).doc(teamId).update({
        'assets': FieldValue.arrayRemove([assetId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing asset from team: $e');
      rethrow;
    }
  }

  /// Delete a team
  Future<void> deleteTeam(String teamId) async {
    try {
      await _firestore.collection(_teamsCollection).doc(teamId).delete();
    } catch (e) {
      print('Error deleting team: $e');
      rethrow;
    }
  }

  /// Get all teams (for admin/management views)
  Stream<List<TeamModel>> getAllTeams() {
    return _firestore.collection(_teamsCollection).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TeamModel.fromFirestore(doc)).toList());
  }
}
