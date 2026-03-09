import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../utils/app_colors.dart';
import '../services/staff_service.dart';
import '../models/user_model.dart';
import '../components/staff/staff_card.dart';
import '../components/staff/staff_details_bottom_sheet.dart';
import '../components/staff/add_staff_dialog.dart';
import '../components/staff/edit_staff_dialog.dart';
import '../components/staff/delete_staff_dialog.dart';

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

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final StaffService _staffService = StaffService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewStaff,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Add Staff',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      body: Container(
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
        child: _buildBody(),
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
    );
  }

  Widget _buildBody() {
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
      margin: EdgeInsets.only(
        top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top,
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
}
