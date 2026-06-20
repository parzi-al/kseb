import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/app_spacing.dart';
import '../utils/app_decorations.dart';
import '../services/staff_service.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../components/staff/staff_card.dart';
import '../components/staff/staff_details_bottom_sheet.dart';
import '../components/staff/add_staff_dialog.dart';
import '../components/staff/edit_staff_dialog.dart';
import '../components/staff/delete_staff_dialog.dart';
import '../components/team/team_dialog.dart';
import '../components/common/app_error_state.dart';
import '../components/common/app_empty_state.dart';
import '../components/common/app_bar_builder.dart';
import '../components/common/app_segmented_tabs.dart';
import '../components/common/staggered_list_item.dart';
import '../components/common/skeleton_loader.dart';

class StaffManagementScreen extends StatefulWidget {
  final String? teamId; // Team ID for supervisor view (optional)
  final UserRole currentUserRole; // Role of the logged-in user

  const StaffManagementScreen({
    super.key,
    this.teamId, // Optional for manager+, required for supervisor
    required this.currentUserRole,
  });

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final StaffService _staffService = StaffService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isFabExpanded = false;
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
              child: Icon(
                _isFabExpanded ? Icons.close : Icons.add,
                size: AppTypography.iconSizeLg,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStaffTabs(),
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildStaffManagementTab(),
                _buildTeamManagementTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return buildAppBar(
        title: '',
        centerTitle: false,
        titleWidget: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search staff...',
            hintStyle: TextStyle(color: AppColors.grey600),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
          ),
          style: AppTypography.bodyStyle,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _toggleSearch,
            tooltip: 'Close search',
          ),
        ],
      );
    }

    return buildAppBar(
      title: 'Staff Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: _toggleSearch,
          tooltip: 'Search staff',
        ),
      ],
    );
  }

  Widget _buildStaffTabs() {
    return AppSegmentedTabs(
      selectedIndex: _selectedTabIndex,
      onChanged: (index) => setState(() => _selectedTabIndex = index),
      tabs: const [
        AppSegmentedTab(icon: Icons.people_rounded, label: 'Staff'),
        AppSegmentedTab(icon: Icons.groups_rounded, label: 'Teams'),
      ],
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
          return AppErrorState(
            message: 'Error: ${snapshot.error}',
            onRetry: () => setState(() {}),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const StaffListSkeleton();
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
      color: AppColors.background,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teams').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Error: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const TeamListSkeleton();
          }

          final teams = snapshot.data?.docs ?? [];

          if (teams.isEmpty) {
            return AppEmptyState(
              icon: Icons.groups_rounded,
              title: 'No Teams Yet',
              subtitle: 'Create your first team to get started',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(context.responsivePadding(AppSpacing.base)),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final teamDoc = teams[index];
              final teamData = teamDoc.data() as Map<String, dynamic>;

              return StaggeredListItem(
                index: index,
                child: _buildTeamCard(teamDoc.id, teamData),
              );
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
      return const AppEmptyState(
        icon: Icons.people_outline,
        title: 'No staff members yet',
        subtitle: 'Add your first staff member to get started',
      );
    }

    if (filteredStaff.isEmpty && _searchQuery.isNotEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'Try searching with different keywords',
      );
    }

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          if (_searchQuery.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(
                context.responsivePadding(AppSpacing.lg),
                AppSpacing.lg,
                context.responsivePadding(AppSpacing.lg),
                AppSpacing.sm,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.info,
                    size: AppTypography.iconSizeMd,
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
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                context.responsivePadding(AppSpacing.lg),
                _searchQuery.isNotEmpty ? AppSpacing.sm : AppSpacing.lg,
                context.responsivePadding(AppSpacing.lg),
                100,
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: filteredStaff.length,
              itemBuilder: (context, index) {
                final staffData =
                    filteredStaff[index].data() as Map<String, dynamic>;
                final staffId = filteredStaff[index].id;
                final staffRole =
                    UserRole.fromString(staffData['role'] ?? 'staff');
                final canEditStaff =
                    widget.currentUserRole.canManage(staffRole);

                return StaggeredListItem(
                  index: index,
                  child: StaffCard(
                    staffData: staffData,
                    staffId: staffId,
                    onTap: () => _showStaffDetails(staffData),
                    onEdit: canEditStaff
                        ? () => _editStaff(staffId, staffData)
                        : () {},
                    onDelete:
                        canEditStaff ? () => _deleteStaff(staffId) : () {},
                    canEdit: canEditStaff,
                  ),
                );
              },
            ),
          ),
        ],
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
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
          child: Icon(icon, size: AppTypography.iconSizeMd),
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
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: AppColors.purple,
                    size: AppTypography.iconSizeLg,
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
                            size: AppTypography.iconSizeSm,
                            color: AppColors.grey600,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            areaCode,
                            style: AppTypography.captionStyle.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Icon(
                            Icons.people_rounded,
                            size: AppTypography.iconSizeSm,
                            color: AppColors.grey600,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            '$memberCount members',
                            style: AppTypography.captionStyle.copyWith(
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
                      icon: Icon(
                        Icons.edit_rounded,
                        color: AppColors.info,
                        size: AppTypography.iconSizeMd,
                      ),
                      onPressed: () => _editTeam(teamId, teamData),
                      tooltip: 'Edit Team',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_rounded,
                        color: AppColors.error,
                        size: AppTypography.iconSizeMd,
                      ),
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
