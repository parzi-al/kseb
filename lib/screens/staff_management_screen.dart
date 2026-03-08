import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/app_spacing.dart';
import '../services/staff_service.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../components/staff/staff_card.dart';
import '../components/staff/staff_details_bottom_sheet.dart';
import '../components/staff/add_staff_dialog.dart';
import '../components/staff/edit_staff_dialog.dart';
import '../components/staff/delete_staff_dialog.dart';
import '../components/team/team_dialog.dart';
import '../components/common/app_loading.dart';

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
      backgroundColor: AppColors.grey50,
      appBar: _buildAppBar(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isFabExpanded) ...[
            _buildMiniFAB(
              label: 'Add Team',
              icon: Icons.group_add_rounded,
              onPressed: _addNewTeam,
              color: AppColors.purple, // DS-EXCEPTION: role color
            ),
            SizedBox(height: AppSpacing.md),
            _buildMiniFAB(
              label: 'Add Staff',
              icon: Icons.person_add_rounded,
              onPressed: _addNewStaff,
              color: AppColors.primary,
            ),
            SizedBox(height: AppSpacing.md),
          ],
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
            },
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
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
      backgroundColor: AppColors.white.withOpacity(0.9),
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.grey500.withOpacity(0.1),
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
                hintStyle: TextStyle(color: AppColors.grey600),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
              ),
              style: AppTypography.subheadingStyle,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            )
          : Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.info.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.people_alt_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Staff Management',
                        style: AppTypography.subheadingStyle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Manage your team',
                        style: AppTypography.captionStyle.copyWith(
                          fontSize: AppTypography.fontSizeXS,
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
          padding: EdgeInsets.only(right: AppSpacing.base),
          child: Container(
            decoration: BoxDecoration(
              color: _isSearching
                  ? AppColors.info.withOpacity(0.1)
                  : AppColors.grey500.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: _isSearching
                    ? AppColors.info.withOpacity(0.3)
                    : AppColors.grey500.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: _isSearching ? AppColors.info : AppColors.textPrimary,
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
          return const Center(child: AppLoading());
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
            AppColors.info.withOpacity(0.05),
            AppColors.white,
            AppColors.grey50,
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
            return const Center(child: AppLoading());
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
                    color: AppColors.grey400,
                  ),
                  SizedBox(height: AppSpacing.base),
                  Text(
                    'No Teams Yet',
                    style: AppTypography.titleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey700,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Create your first team to get started',
                    style: AppTypography.bodyStyle.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.base),
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
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: AppColors.grey400,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            Text(
              'No staff members yet',
              style: AppTypography.headingStyle.copyWith(
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Add your first staff member to get started',
              style: AppTypography.bodyStyle.copyWith(
                color: AppColors.grey500,
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
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.grey400,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            Text(
              'No results found',
              style: AppTypography.headingStyle.copyWith(
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Try searching with different keywords',
              style: AppTypography.bodyStyle.copyWith(
                color: AppColors.grey500,
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
            AppColors.info.withOpacity(0.05),
            AppColors.white,
            AppColors.grey50,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.xl),
          topRight: Radius.circular(AppSpacing.xl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.xl),
                topRight: Radius.circular(AppSpacing.xl),
              ),
            ),
            child: Column(
              children: [
                if (_searchQuery.isNotEmpty) ...[
                  Container(
                    margin: EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, AppSpacing.sm),
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.base, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.info.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: AppColors.info,
                          size: 18,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Found ${filteredStaff.length} result${filteredStaff.length == 1 ? '' : 's'} for "$_searchQuery"',
                            style: AppTypography.bodyMediumStyle.copyWith(
                              color: AppColors.info,
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
                        AppSpacing.base, _searchQuery.isNotEmpty ? AppSpacing.sm : AppSpacing.lg, AppSpacing.base, 100),
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
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: AppTypography.bodyMediumStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: color,
          foregroundColor: AppColors.white,
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
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          onTap: () => _editTeam(teamId, teamData),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                // Team Icon
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.purple.withOpacity(0.8), AppColors.purple], // DS-EXCEPTION: role color
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: AppSpacing.base),
                
                // Team Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.subheadingStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.grey600,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            areaCode,
                            style: AppTypography.captionStyle.copyWith(
                              fontSize: 13,
                              color: AppColors.grey600,
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Icon(
                            Icons.people_rounded,
                            size: 14,
                            color: AppColors.grey600,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            '$memberCount members',
                            style: AppTypography.captionStyle.copyWith(
                              fontSize: 13,
                              color: AppColors.grey600,
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
                      icon: Icon(Icons.edit_rounded, color: AppColors.info),
                      onPressed: () => _editTeam(teamId, teamData),
                      tooltip: 'Edit Team',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded, color: AppColors.error),
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
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error),
            SizedBox(width: AppSpacing.md),
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
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting team: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
