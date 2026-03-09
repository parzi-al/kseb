import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_spacing.dart';

/// Strength level for a password.
enum PasswordStrength {
  weak,
  fair,
  strong;

  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  /// Number of segments to fill (out of 3).
  int get filledSegments {
    switch (this) {
      case PasswordStrength.weak:
        return 1;
      case PasswordStrength.fair:
        return 2;
      case PasswordStrength.strong:
        return 3;
    }
  }
}

/// Visual password strength meter widget (FR-013, FR-014).
///
/// Displays a 3-segment horizontal bar with a text label.
/// Scoring is based on additive heuristics:
/// - Length ≥ 6: +1
/// - Length ≥ 10: +1
/// - Contains uppercase: +1
/// - Contains lowercase: +1
/// - Contains digit: +1
/// - Contains special character: +1
///
/// Thresholds: 0-2 = Weak, 3-4 = Fair, 5-6 = Strong.
///
/// Returns [SizedBox.shrink] when [password] is empty.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  /// Calculate the strength score (0-6) for the given password.
  static int calculateScore(String password) {
    if (password.isEmpty) return 0;

    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/~`]').hasMatch(password)) {
      score++;
    }
    return score;
  }

  /// Map score to strength level.
  static PasswordStrength getStrength(int score) {
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.fair;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final score = calculateScore(password);
    final strength = getStrength(score);

    return Semantics(
      label: 'Password strength: ${strength.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          // 3-segment bar
          Row(
            children: List.generate(3, (index) {
              final isFilled = index < strength.filledSegments;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < 2 ? AppSpacing.xs : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isFilled ? strength.color : AppColors.grey200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Label text
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: AppTypography.captionStyle.copyWith(
              color: strength.color,
              fontWeight: FontWeight.w500,
            ),
            child: Text(strength.label),
          ),
        ],
      ),
    );
  }
}
