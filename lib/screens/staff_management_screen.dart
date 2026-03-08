import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../utils/app_colors.dart';
import '../services/staff_service.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../components/staff/staff_card.dart';
import '../components/staff/staff_details_bottom_sheet.dart';
import '../components/staff/add_staff_dialog.dart';
import '../components/staff/edit_staff_dialog.dart';
import '../components/staff/delete_staff_dialog.dart';
import '../components/team/team_dialog.dart';

class StaffManagementScreen extends StatefulWidget {
  final String? teamId; // Team ID for supervisor view (optional)
  final UserRole currentUserRole; // Role of the logged-in user

  const StaffManagementScreen({
    Key? key,
    this.teamId, // Optional for manager+, required for supervisor
    required this.currentUserRole,
  }) : super(key: key);

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen>
    with SingleTickerProviderStateMixin {
  final StaffService _staffService = StaffService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isFabExpanded = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isFabExpanded) ...[
            _buildMiniFAB(
              label: 'Add Team',
              icon: Icons.group_add_rounded,
              onPressed: _addNewTeam,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildMiniFAB(
              label: 'Add Staff',
              icon: Icons.person_add_rounded,
              onPressed: _addNewStaff,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 8,
            child: AnimatedRotation(
              turns: _isFabExpanded ? 0.125 : 0, // 45 degrees rotation
              duration: const Duration(milliseconds: 200),
              child: Icon(_isFabExpanded ? Icons.close : Icons.add, size: 28),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStaffManagementTab(),
          _buildTeamManagementTab(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.9),
      foregroundColor: Colors.black87,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search staff...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Staff Management',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Manage your team',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            decoration: BoxDecoration(
              color: _isSearching
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isSearching
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: _isSearching ? Colors.blue.shade700 : Colors.black87,
                size: 20,
              ),
              onPressed: _toggleSearch,
            ),
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.people_rounded),
            text: 'Staff',
          ),
          Tab(
            icon: Icon(Icons.groups_rounded),
            text: 'Teams',
          ),
        ],
      ),
    );
  }

  Widget _buildStaffManagementTab() {
    // Manager+ sees all staff, Supervisor sees only their team
    final bool showAllStaff = widget.currentUserRole == UserRole.manager ||
        widget.currentUserRole == UserRole.coo ||
        widget.currentUserRole == UserRole.director;

    return StreamBuilder<QuerySnapshot>(
      stream: showAllStaff
          ? _staffService.getAllStaffStream() // Manager+ sees all staff
          : _staffService
              .getStaffStream(widget.teamId!), // Supervisor sees only team
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter staff based on role hierarchy
        final allStaff = snapshot.data?.docs ?? [];
        
        final manageableStaff = allStaff.where((doc) {
          final staffData = doc.data() as Map<String, dynamic>;
          final staffRole = UserRole.fromString(staffData['role'] ?? 'staff');
          // User can only see staff they can manage
          return widget.currentUserRole.canManage(staffRole);
        }).toList();

        return _buildStaffList(manageableStaff);
      },
    );
  }

  Widget _buildTeamManagementTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.grey.shade50,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teams').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final teams = snapshot.data?.docs ?? [];

          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Teams Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first team to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final teamDoc = teams[index];
              final teamData = teamDoc.data() as Map<String, dynamic>;
              
              return _buildTeamCard(teamDoc.id, teamData);
            },
          );
        },
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  List<QueryDocumentSnapshot> _filterStaff(List<QueryDocumentSnapshot> staff) {
    if (_searchQuery.isEmpty) {
      return staff;
    }

    return staff.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final phone = (data['phone'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();

      return name.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          email.contains(_searchQuery);
    }).toList();
  }

  Widget _buildStaffList(List<QueryDocumentSnapshot> staff) {
    final filteredStaff = _filterStaff(staff);

    if (staff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No staff members yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first staff member to get started',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (filteredStaff.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.grey.shade50,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                if (_searchQuery.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Colors.blue.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Found ${filteredStaff.length} result${filteredStaff.length == 1 ? '' : 's'} for "$_searchQuery"',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                        16, _searchQuery.isNotEmpty ? 8 : 20, 16, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredStaff.length,
                    itemBuilder: (context, index) {
                      final staffData =
                          filteredStaff[index].data() as Map<String, dynamic>;
                      final staffId = filteredStaff[index].id;
                      final staffRole =
                          UserRole.fromString(staffData['role'] ?? 'staff');

                      // Check if current user can edit this staff member
                      final canEditStaff =
                          widget.currentUserRole.canManage(staffRole);

                      return StaffCard(
                        staffData: staffData,
                        staffId: staffId,
                        onTap: () => _showStaffDetails(staffData),
                        onEdit: canEditStaff
                            ? () => _editStaff(staffId, staffData)
                            : () {},
                        onDelete:
                            canEditStaff ? () => _deleteStaff(staffId) : () {},
                        canEdit: canEditStaff,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStaffDetails(Map<String, dynamic> staffData) {
    StaffDetailsBottomSheet.show(context, staffData);
  }

  void _addNewTeam() {
    setState(() {
      _isFabExpanded = false; // Close FAB menu
    });

    showDialog(
      context: context,
      builder: (context) => const TeamDialog(),
    ).then((success) {
      if (success == true) {
        setState(() {}); // Refresh to show new team
      }
    });
  }

  Widget _buildMiniFAB({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          heroTag: label, // Unique hero tag for each FAB
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }

  void _editStaff(String staffId, Map<String, dynamic> staffData) {
    EditStaffDialog.show(
      context,
      staffId,
      staffData,
      currentUserRole: widget.currentUserRole,
      onStaffUpdated: () {
        setState(() {}); // Force a rebuild to ensure UI is updated
      },
    );
  }

  void _deleteStaff(String staffId) {
    DeleteStaffDialog.show(
      context,
      staffId,
      onStaffDeleted: () {
        setState(() {}); // Force a rebuild to ensure UI is updated
      },
    );
  }

  void _addNewStaff() {
    AddStaffDialog.show(
      context,
      defaultTeamId:
          widget.teamId, // Pass current team as default (can be null)
      currentUserRole: widget.currentUserRole,
      onStaffAdded: () {
        // The stream will automatically update, but we can add any additional logic here if needed
        setState(() {}); // Force a rebuild to ensure UI is updated
      },
    );
  }

  Widget _buildTeamCard(String teamId, Map<String, dynamic> teamData) {
    final name = teamData['name'] ?? 'Unnamed Team';
    final areaCode = teamData['areaCode'] ?? '';
    final memberCount = (teamData['members'] as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _editTeam(teamId, teamData),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Team Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Team Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            areaCode,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.people_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$memberCount members',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: Colors.blue.shade600),
                      onPressed: () => _editTeam(teamId, teamData),
                      tooltip: 'Edit Team',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded, color: Colors.red.shade600),
                      onPressed: () => _deleteTeam(teamId, name),
                      tooltip: 'Delete Team',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editTeam(String teamId, Map<String, dynamic> teamData) {
    // Convert team data to TeamModel
    final team = TeamModel.fromMap(teamData, teamId);
    
    showDialog(
      context: context,
      builder: (context) => TeamDialog(team: team),
    ).then((success) {
      if (success == true) {
        setState(() {}); // Refresh to show updated team
      }
    });
  }

  void _deleteTeam(String teamId, String teamName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Delete Team'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$teamName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('teams')
                    .doc(teamId)
                    .delete();
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Team "$teamName" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting team: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
