import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../components/common/app_bar_builder.dart';
import '../components/common/modern_dropdown.dart';
import '../models/user_model.dart';
import '../services/approval_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_decorations.dart';
import '../utils/app_spacing.dart';
import '../utils/app_toast.dart';
import '../utils/app_typography.dart';

class MaterialApprovalScreen extends StatefulWidget {
  const MaterialApprovalScreen({super.key});

  @override
  State<MaterialApprovalScreen> createState() => _MaterialApprovalScreenState();
}

class _MaterialApprovalScreenState extends State<MaterialApprovalScreen> {
  final ApprovalService _approvalService = ApprovalService();
  final TextEditingController _historySearchController =
      TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _busyRequestId;
  String _historyStatusFilter = 'All';
  UserRole? _historyRoleFilter;
  DateTime? _historyDateFilter;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _historySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _approvalService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppErrorHandler.handleError(context, e,
            customMessage: 'Failed to load approver profile');
      }
    }
  }

  Future<void> _approve(String requestId) async {
    setState(() => _busyRequestId = requestId);
    try {
      await _approvalService.approveMaterialRequest(requestId);
      if (mounted) {
        AppToast.showSuccess(context, 'Request approved.');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, _approvalErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _busyRequestId = null);
      }
    }
  }

  Future<void> _reject(String requestId) async {
    setState(() => _busyRequestId = requestId);
    try {
      await _approvalService.rejectMaterialRequest(requestId);
      if (mounted) {
        AppToast.showSuccess(context, 'Request rejected.');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, _approvalErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _busyRequestId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: buildAppBar(title: 'Material Approvals'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    color: AppColors.surface,
                    child: TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'Pending'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('material_requests')
                          .where('status',
                              whereIn: ['Pending', 'Approved', 'Rejected'])
                          .orderBy('requestTimestamp', descending: true)
                          .limit(200)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Unable to load requests.',
                              style: AppTypography.bodyStyle,
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final visibleRequests =
                            _visibleRequests(snapshot.data!.docs);
                        final pendingRequests = visibleRequests
                            .where((doc) =>
                                _requestData(doc)['status'] == 'Pending')
                            .toList();
                        final historyRequests = visibleRequests
                            .where((doc) =>
                                _requestData(doc)['status'] == 'Approved' ||
                                _requestData(doc)['status'] == 'Rejected')
                            .where(_matchesHistoryFilters)
                            .toList();

                        return TabBarView(
                          children: [
                            _buildRequestList(
                              pendingRequests,
                              emptyMessage:
                                  'No pending requests for your approval.',
                            ),
                            Column(
                              children: [
                                _buildHistoryFilters(),
                                Expanded(
                                  child: _buildRequestList(
                                    historyRequests,
                                    emptyMessage:
                                        'No approved or rejected requests match these filters.',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _approvalErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return 'Unable to process request. Please try again.';
    }
    return message;
  }

  List<QueryDocumentSnapshot> _visibleRequests(
    List<QueryDocumentSnapshot> docs,
  ) {
    final requests = docs.where((doc) {
      final data = _requestData(doc);
      final action = data['action'] as String?;
      final status = data['status'] as String?;
      final isSupportedAction = action == ApprovalAction.addMaterial.value ||
          action == ApprovalAction.withdrawMaterial.value;
      final isVisibleStatus =
          status == 'Pending' || status == 'Approved' || status == 'Rejected';
      final requesterRole =
          UserRole.fromString(data['requestedByRole'] ?? 'staff');

      return isSupportedAction &&
          isVisibleStatus &&
          (_currentUser?.role.canApproveRequestFrom(requesterRole) ?? false);
    }).toList();

    requests.sort((a, b) {
      final aData = _requestData(a);
      final bData = _requestData(b);
      final aStatusOrder = aData['status'] == 'Pending' ? 0 : 1;
      final bStatusOrder = bData['status'] == 'Pending' ? 0 : 1;
      if (aStatusOrder != bStatusOrder) {
        return aStatusOrder.compareTo(bStatusOrder);
      }

      final aTime = aData['requestTimestamp'];
      final bTime = bData['requestTimestamp'];
      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }
      return 0;
    });

    return requests;
  }

  bool _matchesHistoryFilters(QueryDocumentSnapshot doc) {
    final data = _requestData(doc);
    final status = data['status'] as String?;
    final role = UserRole.fromString(data['requestedByRole'] ?? 'staff');
    final search = _historySearchController.text.trim().toLowerCase();

    if (_historyStatusFilter != 'All' && status != _historyStatusFilter) {
      return false;
    }
    if (_historyRoleFilter != null && role != _historyRoleFilter) {
      return false;
    }
    if (_historyDateFilter != null) {
      final timestamp = data['requestTimestamp'];
      if (timestamp is! Timestamp) return false;
      final date = timestamp.toDate();
      if (date.year != _historyDateFilter!.year ||
          date.month != _historyDateFilter!.month ||
          date.day != _historyDateFilter!.day) {
        return false;
      }
    }
    if (search.isNotEmpty) {
      final haystack = [
        data['materialName'],
        data['requestedByName'],
        data['requestedByEmail'],
      ].whereType<String>().join(' ').toLowerCase();
      if (!haystack.contains(search)) return false;
    }

    return true;
  }

  Map<String, dynamic> _requestData(QueryDocumentSnapshot doc) {
    return doc.data() as Map<String, dynamic>;
  }

  Widget _buildHistoryFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        decoration: AppDecorations.modernCardDecoration,
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _historySearchController,
              onChanged: (_) => setState(() {}),
              style: AppTypography.bodyMediumStyle,
              decoration: InputDecoration(
                hintText: 'Search material or requester',
                hintStyle: AppTypography.captionStyle.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: _historySearchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          setState(() => _historySearchController.clear());
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                filled: true,
                fillColor: AppColors.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(color: AppColors.grey300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(color: AppColors.grey300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.4),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStatusFilter(),
                _buildRoleFilter(),
                _buildFilterButton(
                  icon: Icons.calendar_today_rounded,
                  label: _historyDateFilter == null
                      ? 'Date'
                      : '${_historyDateFilter!.day}/${_historyDateFilter!.month}/${_historyDateFilter!.year}',
                  onPressed: _pickHistoryDate,
                ),
                if (_hasActiveHistoryFilters)
                  _buildFilterButton(
                    icon: Icons.clear_rounded,
                    label: 'Clear',
                    onPressed: () {
                      setState(() {
                        _historyStatusFilter = 'All';
                        _historyRoleFilter = null;
                        _historyDateFilter = null;
                        _historySearchController.clear();
                      });
                    },
                    foregroundColor: AppColors.error,
                    backgroundColor: AppColors.error.withValues(alpha: 0.08),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasActiveHistoryFilters {
    return _historyDateFilter != null ||
        _historyRoleFilter != null ||
        _historyStatusFilter != 'All' ||
        _historySearchController.text.isNotEmpty;
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    final color = foregroundColor ?? AppColors.textSecondary;

    return SizedBox(
      height: 44,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: color,
          backgroundColor: backgroundColor ?? AppColors.grey50,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(
              color: foregroundColor == null
                  ? AppColors.grey300
                  : color.withValues(alpha: 0.25),
            ),
          ),
          textStyle: AppTypography.captionStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      width: 150,
      child: ModernDropdown<String>(
        value: _historyStatusFilter,
        label: 'Status',
        prefixIcon: Icons.tune_rounded,
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        items: const [
          DropdownMenuItem(value: 'All', child: Text('All')),
          DropdownMenuItem(value: 'Approved', child: Text('Approved')),
          DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _historyStatusFilter = value);
        },
      ),
    );
  }

  Widget _buildRoleFilter() {
    return SizedBox(
      width: 180,
      child: ModernDropdown<UserRole?>(
        value: _historyRoleFilter,
        label: 'Role',
        hint: 'Role',
        prefixIcon: Icons.badge_outlined,
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        items: [
          const DropdownMenuItem<UserRole?>(
            value: null,
            child: Text('All roles'),
          ),
          ...UserRole.values.map(
            (role) => DropdownMenuItem<UserRole?>(
              value: role,
              child: Text(role.displayName),
            ),
          ),
        ],
        onChanged: (value) => setState(() => _historyRoleFilter = value),
      ),
    );
  }

  Future<void> _pickHistoryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _historyDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _historyDateFilter = picked);
    }
  }

  Widget _buildRequestList(
    List<QueryDocumentSnapshot> requests, {
    required String emptyMessage,
  }) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: AppTypography.bodyStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemBuilder: (context, index) {
        final doc = requests[index];
        return _buildRequestCard(doc.id, _requestData(doc));
      },
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.base),
      itemCount: requests.length,
    );
  }

  Widget _buildRequestCard(String requestId, Map<String, dynamic> data) {
    final action = data['action'] == ApprovalAction.addMaterial.value
        ? 'Add Material'
        : 'Withdraw Material';
    final requesterRole =
        UserRole.fromString(data['requestedByRole'] ?? 'staff').displayName;
    final quantity = data['requestedQuantity']?.toString() ?? '-';
    final unit = data['unit'] ?? '';
    final status = data['status'] ?? 'Pending';
    final isPending = status == 'Pending';
    final isRejected = status == 'Rejected';
    final isBusy = _busyRequestId == requestId;
    final statusColor = isPending
        ? AppColors.warning
        : isRejected
            ? AppColors.error
            : AppColors.success;

    return Container(
      decoration: AppDecorations.modernCardDecoration,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(action, style: AppTypography.subheadingStyle),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  status,
                  style: AppTypography.captionStyle.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data['materialName'] ?? 'Unknown Material',
            style: AppTypography.bodyMediumStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$quantity $unit • Raised by ${data['requestedByName'] ?? data['requestedByEmail'] ?? 'User'} ($requesterRole)',
            style: AppTypography.captionStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if ((data['purpose'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              data['purpose'],
              style: AppTypography.captionStyle,
            ),
          ],
          if (!isPending && data['approvedByEmail'] != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${isRejected ? 'Rejected' : 'Approved'} by ${data['approvedByEmail']}',
              style: AppTypography.captionStyle.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : () => _reject(requestId),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy ? null : () => _approve(requestId),
                    child: Text(isBusy ? 'Please wait...' : 'Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
