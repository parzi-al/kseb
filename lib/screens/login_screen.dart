import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/app_spacing.dart';
import '../utils/app_decorations.dart';
import '../utils/app_toast.dart';
import '../components/common/app_button.dart';
import '../components/common/app_loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- Functions ---
  Future<void> _signIn() async {
    // Basic validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AppToast.showError(context, 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use Firebase Auth to sign in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // If login is successful, the StreamBuilder in main.dart will handle navigation.
      // No need for Navigator.push here.
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(context, e);
      }
    } catch (e) {
      // Handle other unexpected errors
      if (mounted) {
        AppErrorHandler.handleError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.responsivePadding(AppSpacing.xl)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: context.responsiveSpacing(60)),
              // Clean Modern Header
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                        context.responsivePadding(AppSpacing.lg)),
                    decoration: BoxDecoration(
                      color: AppColors.primaryWithLowOpacity,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      size: context.responsiveHeight(40),
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),
                  Text(
                    'KSEB',
                    style: AppTypography.displayLargeStyle,
                  ),
                  SizedBox(height: context.responsiveSpacing(AppSpacing.sm)),
                  Text(
                    'Worker Portal',
                    style: AppTypography.bodyStyle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing(48)),
              Text(
                'Welcome Back',
                style: AppTypography.displayStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.responsiveSpacing(AppSpacing.sm)),
              Text(
                'Sign in to continue',
                style: AppTypography.bodyStyle.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.responsiveSpacing(48)),
              // Modern Email Field
              Container(
                decoration: AppDecorations.modernCardDecoration,
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodyMediumStyle,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(AppSpacing.md),
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithLowOpacity,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        color: AppColors.primary,
                        size: context.responsiveHeight(20),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.responsiveSpacing(AppSpacing.lg)),
              // Modern Password Field
              Container(
                decoration: AppDecorations.modernCardDecoration,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: AppTypography.bodyMediumStyle,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(AppSpacing.md),
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithLowOpacity,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        color: AppColors.primary,
                        size: context.responsiveHeight(20),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.responsiveSpacing(AppSpacing.xxl)),
              // Modern Login Button
              _isLoading
                  ? const AppLoading(variant: AppLoadingVariant.inline)
                  : AppButton(
                      label: 'SIGN IN',
                      onPressed: _signIn,
                    ),
              SizedBox(height: context.responsiveSpacing(AppSpacing.xxl)),
              // Modern Footer links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      AppToast.showInfo(
                          context, 'Forgot Password feature coming soon! 🔐');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    ' | ',
                    style: TextStyle(
                      color: AppColors.grey300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      AppToast.showInfo(
                          context, 'Sign Up feature coming soon! 📝');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }
}
