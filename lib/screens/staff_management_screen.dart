import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';

class StaffManagementScreen extends StatefulWidget {
  final String supervisorId;

  const StaffManagementScreen({
    Key? key,
    required this.supervisorId,
  }) : super(key: key);

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  static const String _staffDetailsCollection = 'staff_details';
  static const String _supervisorStaffCollection = 'supervisor-staff';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _staffCollection;
  bool _isLoading = false;
  String? _fetchedStaffId;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  // Debouncer for phone number search
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _staffCollection = _firestore.collection('staff_details');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStaffDetails(String phoneNumber) async {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Clear fields if phone number is empty
    if (phoneNumber.isEmpty) {
      _nameController.clear();
      _emailController.clear();
      _fetchedStaffId = null;
      return;
    }

    // Set new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        _setLoading(true);

        // Query staff_details collection
        final staffQuery = await _firestore
            .collection(_staffDetailsCollection)
            .where('phone', isEqualTo: phoneNumber)
            .get();

        if (staffQuery.docs.isNotEmpty) {
          final staffData =
              staffQuery.docs.first.data() as Map<String, dynamic>;
          _fetchedStaffId = staffQuery.docs.first.id;

          setState(() {
            _nameController.text = staffData['name'] ?? '';
            _emailController.text = staffData['email'] ?? '';
          });

          AppToast.showSuccess(context, 'Staff details found');
        } else {
          setState(() {
            _nameController.clear();
            _emailController.clear();
            _fetchedStaffId = null;
          });
          AppToast.showError(context, 'No staff found with this number');
        }
      } catch (e) {
        AppToast.showError(context, 'Error fetching staff details: $e');
      } finally {
        _setLoading(false);
      }
    });
  }

  Future<void> _linkStaffToSupervisor() async {
    try {
      if (_fetchedStaffId == null) {
        AppToast.showError(context, 'No staff selected');
        return;
      }

      // Add to supervisor_staff collection
      await _firestore
          .collection(_supervisorStaffCollection)
          .doc(widget.supervisorId)
          .collection('staff')
          .add({
        'staffId': _fetchedStaffId,
        'phoneNumber': _phoneController.text,
        'addedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      AppToast.showSuccess(context, 'Staff added successfully');
    } catch (e) {
      AppToast.showError(context, 'Error adding staff: $e');
    }
  }

  void _setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  Future<void> _handleError(
      BuildContext context, dynamic error, String action) async {
    _setLoading(false);
    AppToast.showError(context, 'Error $action staff member: $error');
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.8),
      foregroundColor: Colors.black87,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Colors.black87,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Staff Management',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.black87,
                size: 20,
              ),
              onPressed: () {
                // TODO: Implement search
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffList(List<QueryDocumentSnapshot> staff) {
    if (staff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No staff members yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                24,
                AppBar().preferredSize.height + 40,
                24,
                24,
              ),
              itemCount: staff.length,
              itemBuilder: (context, index) {
                final staffData = staff[index].data() as Map<String, dynamic>;
                final staffId = staff[index].id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showStaffDetails(context, staffData),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: _buildAvatar(staffData['name']),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      staffData['name'] ?? 'Staff Member',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (staffData['phone'] != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone_rounded,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            staffData['phone'],
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.edit_rounded,
                                    color: Colors.blue.shade700,
                                    onTap: () => _showEditStaffDialog(
                                        context, staffId, staffData),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionButton(
                                    icon: Icons.delete_rounded,
                                    color: Colors.red,
                                    onTap: () => _showDeleteConfirmation(
                                        context, staffId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )));
  }

  Widget _buildAvatar(String? name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (name?.isNotEmpty ?? false)
              ? name!.substring(0, 1).toUpperCase()
              : 'S',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: _staffCollection
          .where('supervisorId', isEqualTo: widget.supervisorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildStaffList(snapshot.data?.docs ?? []);
      },
    );
  }

  void _addNewStaff() {
    _showAddStaffDialog(context);
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  void _showStaffDetails(BuildContext context, Map<String, dynamic> staffData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade500,
                        Colors.blue.shade700,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            (staffData['name']?.isNotEmpty ?? false)
                                ? staffData['name']!
                                    .substring(0, 1)
                                    .toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        staffData['name'] ?? 'Staff Member',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _detailRow('Name', staffData['name'] ?? 'N/A'),
                  _detailRow('Email', staffData['email'] ?? 'N/A'),
                  _detailRow('Phone', staffData['phone'] ?? 'N/A'),
                  _detailRow('Role', staffData['role'] ?? 'N/A'),
                  _detailRow(
                    'Join Date',
                    staffData['joinDate'] != null
                        ? (staffData['joinDate'] as Timestamp)
                            .toDate()
                            .toString()
                            .split(' ')[0]
                        : 'N/A',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddStaffDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();

    showDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        context: context,
        builder: (context) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.9),
                elevation: 0,
                title: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Add New Staff'),
                  ],
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) => _fetchStaffDetails(value),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Phone number is required'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Staff Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Phone number is required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: AppColors.grey300),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              try {
                                await _staffCollection.add({
                                  'name': _nameController.text,
                                  'phone': _phoneController.text,
                                  'email': _emailController.text,
                                  'supervisorId': widget.supervisorId,
                                  'joinDate': Timestamp.now(),
                                });
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle,
                                              color: Colors.white),
                                          const SizedBox(width: 8),
                                          const Text(
                                              'Staff added successfully'),
                                        ],
                                      ),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                AppToast.showError(
                                    context, 'Error adding staff member: $e');
                              }
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ));
  }

  Future<void> _showEditStaffDialog(
    BuildContext context,
    String staffId,
    Map<String, dynamic> staffData,
  ) async {
    final nameController = TextEditingController(text: staffData['name']);
    final emailController = TextEditingController(text: staffData['email']);
    final phoneController = TextEditingController(text: staffData['phone']);
    final roleController = TextEditingController(text: staffData['role']);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Staff'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Email is required' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Phone is required' : null,
                ),
                TextFormField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Role is required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await _staffCollection.doc(staffId).update({
                    'name': nameController.text,
                    'email': emailController.text,
                    'phone': phoneController.text,
                    'role': roleController.text,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    AppToast.showSuccess(
                        context, 'Staff member updated successfully');
                  }
                } catch (e) {
                  AppToast.showError(
                      context, 'Error updating staff member: $e');
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, String staffId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content:
            const Text('Are you sure you want to delete this staff member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _staffCollection.doc(staffId).delete();
                if (mounted) {
                  Navigator.pop(context);
                  AppToast.showSuccess(
                      context, 'Staff member deleted successfully');
                }
              } catch (e) {
                AppToast.showError(context, 'Error deleting staff member: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
        icon: const Icon(Icons.add),
        label: const Text('Add Staff'),
      ),
      body: _buildBody(),
    );
  }
}
