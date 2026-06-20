import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppToast {
  static void showError(BuildContext context, String message) {
    _showCustomToast(
      context: context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _showCustomToast(
      context: context,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showCustomToast(
      context: context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showCustomToast(
      context: context,
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info_outline_rounded,
    );
  }

  static void _showCustomToast({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: backgroundColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: messenger.hideCurrentSnackBar,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: backgroundColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
        elevation: 0,
      ),
    );
  }
}

class AppErrorHandler {
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
  }) {
    final errorMessage = customMessage ?? _getErrorMessage(error);
    AppToast.showError(context, errorMessage);
    debugPrint('Error handled: $error');
  }

  static String _getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network')) {
      return 'Network connection error. Please check your internet.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check your access rights.';
    } else if (errorString.contains('not-found')) {
      return 'Requested data not found.';
    } else if (errorString.contains('already-exists')) {
      return 'This record already exists.';
    } else if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    } else if (errorString.contains('email-already-in-use')) {
      return 'This email is already registered. Please use a different email.';
    } else if (errorString.contains('user-not-found')) {
      return 'No account found with this email address.';
    } else if (errorString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorString.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (errorString.contains('operation-not-allowed')) {
      return 'This operation is not allowed.';
    } else if (errorString.contains('invalid-verification-code')) {
      return 'Invalid verification code. Please try again.';
    } else if (errorString.contains('session-expired')) {
      return 'Your session has expired. Please log in again.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
}
