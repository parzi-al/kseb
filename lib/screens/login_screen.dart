import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';

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
          padding:
              EdgeInsets.all(AppColors.getResponsivePadding(context, 24.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppColors.getResponsiveSpacing(context, 60)),
              // Clean Modern Header
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                        AppColors.getResponsivePadding(context, 20)),
                    decoration: BoxDecoration(
                      color: AppColors.primaryWithLowOpacity,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      size: AppColors.getResponsiveHeight(context, 40),
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: AppColors.getResponsiveSpacing(context, 24)),
                  Text(
                    'KSEB',
                    style: AppColors.displayLargeStyle,
                  ),
                  SizedBox(height: AppColors.getResponsiveSpacing(context, 8)),
                  Text(
                    'Worker Portal',
                    style: AppColors.bodyStyle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppColors.getResponsiveSpacing(context, 48)),
              Text(
                'Welcome Back',
                style: AppColors.displayStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppColors.getResponsiveSpacing(context, 8)),
              Text(
                'Sign in to continue',
                style: AppColors.bodyStyle.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppColors.getResponsiveSpacing(context, 48)),
              // Modern Email Field
              Container(
                decoration: AppColors.modernCardDecoration,
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithLowOpacity,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        color: AppColors.primary,
                        size: AppColors.getResponsiveHeight(context, 20),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppColors.getResponsiveSpacing(context, 20)),
              // Modern Password Field
              Container(
                decoration: AppColors.modernCardDecoration,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithLowOpacity,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        color: AppColors.primary,
                        size: AppColors.getResponsiveHeight(context, 20),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppColors.getResponsiveSpacing(context, 32)),
              // Modern Login Button
              _isLoading
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: AppColors.getResponsiveHeight(context, 56),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _signIn,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Text(
                              'SIGN IN',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: AppColors.fontSizeBase,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: AppColors.getResponsiveSpacing(context, 32)),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppColors.getResponsiveSpacing(context, 24)),
            ],
          ),
        ),
      ),
    );
  }
}
