import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../components/common/app_bar_builder.dart';
import '../components/common/app_loading.dart';
import '../components/common/app_error_state.dart';
import '../components/common/app_empty_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class BonusHistoryScreen extends StatefulWidget {
  const BonusHistoryScreen({super.key});

  @override
  State<BonusHistoryScreen> createState() => _BonusHistoryScreenState();
}

class _BonusHistoryScreenState extends State<BonusHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  String? _selectedUserId;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;
  bool _isCooOrDirector = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userModel = await _userService.getUserByEmail(user.email!);
      if (userModel != null) {
        _isCooOrDirector = userModel.role == UserRole.coo ||
            userModel.role == UserRole.director;

        if (_isCooOrDirector) {
          // COO/Director can see all users
          await _loadUsers();
        } else {
          // Regular users can only see their own history
          setState(() {
            _selectedUserId = user.uid;
            _isLoadingUsers = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final usersSnapshot = await _firestore.collection('users').get();

      _users = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'staff',
          'bonusPoints': data['bonusPoints'] ?? 0,
          'bonusAmount': (data['bonusAmount'] ?? 0).toDouble(),
        };
      }).toList();

      // Sort by name
      _users
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      setState(() {
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(title: 'Bonus History'),
      body: Column(
        children: [
          // User Selection (only for COO/Director)
          if (_isCooOrDirector)
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Employee',
                    style: AppTypography.subheadingStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _isLoadingUsers
                      ? const Center(
                          child: AppLoading(),
                        )
                      : _buildUserDropdown(),
                ],
              ),
            ),
          // Bonus History List
          Expanded(
            child: _selectedUserId == null
                ? _buildEmptyState()
                : _buildBonusHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.grey300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedUserId,
          hint: Text(
            'Select an employee',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: _users.map((user) {
            return DropdownMenuItem<String>(
              value: user['id'],
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user['name'],
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${user['email']} • ${UserRole.fromString(user['role']).displayName}',
                          style: AppTypography.captionStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.amber, size: 16), // DS-EXCEPTION: status color
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${user['bonusPoints']}',
                            style: AppTypography.captionStyle.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${user['bonusAmount'].toStringAsFixed(2)}',
                        style: AppTypography.captionStyle.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedUserId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primaryWithLowOpacity,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Select Employee',
              style: AppTypography.titleStyle,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose an employee to view their bonus history',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.fontSizeLG,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bonuses')
          .where('userId', isEqualTo: _selectedUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: AppLoading(),
          );
        }

        if (snapshot.hasError) {
          return AppErrorState(
            message: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const AppEmptyState(
            icon: Icons.inbox_rounded,
            title: 'No Bonus History',
            subtitle: 'No bonus records yet',
          );
        }

        // Sort bonuses by updatedAt in app code to avoid composite index requirement
        final bonuses = snapshot.data!.docs.toList();
        bonuses.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime =
              (aData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime =
              (bData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime); // Descending order (newest first)
        });

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: bonuses.length,
          itemBuilder: (context, index) {
            final bonus = bonuses[index].data() as Map<String, dynamic>;
            final points = bonus['points'] ?? 0;
            final amount = (bonus['amount'] ?? 0).toDouble();
            final reason = bonus['reason'] as String?;
            final updatedAt = (bonus['updatedAt'] as Timestamp?)?.toDate();
            final updatedBy = bonus['updatedBy'] as String?;

            final isPositive = points >= 0 || amount >= 0;

            return FutureBuilder<DocumentSnapshot>(
              future: updatedBy != null
                  ? _firestore.collection('users').doc(updatedBy).get()
                  : null,
              builder: (context, userSnapshot) {
                String updatedByName = 'Unknown';
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  updatedByName = userData['name'] ?? 'Unknown';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.base),
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                    border: Border.all(
                      color: isPositive
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.error.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Icon(
                              isPositive
                                  ? Icons.add_circle_rounded
                                  : Icons.remove_circle_rounded,
                              color: isPositive
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.base),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPositive ? 'Bonus Added' : 'Bonus Removed',
                                  style: AppTypography.subheadingStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'By $updatedByName',
                                  style: AppTypography.captionStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (points != 0)
                            _buildBonusValue(
                              'Points',
                              '${points >= 0 ? '+' : ''}$points',
                              Icons.star_rounded,
                              Colors.amber, // DS-EXCEPTION: status color
                            ),
                          if (amount != 0)
                            _buildBonusValue(
                              'Amount',
                              '${amount >= 0 ? '+' : ''}₹${amount.abs().toStringAsFixed(2)}',
                              Icons.currency_rupee_rounded,
                              Colors.green, // DS-EXCEPTION: status color
                            ),
                        ],
                      ),
                      if (reason != null && reason.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWithLowOpacity,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reason',
                                      style: AppTypography.captionStyle.copyWith(
                                        fontSize: AppTypography.fontSizeXS,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      reason,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (updatedAt != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Divider(color: AppColors.grey300),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM dd, yyyy • h:mm a')
                                  .format(updatedAt),
                              style: AppTypography.captionStyle,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBonusValue(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.captionStyle,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.headingStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
