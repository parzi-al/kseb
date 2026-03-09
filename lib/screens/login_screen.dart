import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/app_spacing.dart';
import '../utils/app_decorations.dart';
import '../utils/app_toast.dart';
import '../utils/animation_constants.dart';
import '../components/common/app_button.dart';
import '../components/common/app_loading.dart';
import '../components/common/password_strength_indicator.dart';
import '../services/auth_service.dart';
import '../services/login_rate_limiter.dart';

class LoginScreen extends StatefulWidget {
  /// Optional [AuthService] for dependency injection (used in tests).
  final AuthService? authService;

  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _passwordText = '';

  // Auth service and rate limiter
  late final AuthService _authService;
  final LoginRateLimiter _rateLimiter = LoginRateLimiter();
  int _cooldownRemaining = 0;
  StreamSubscription<int>? _cooldownSub;

  // Icon animation
  late final AnimationController _iconAnimController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconGlow;
  bool _animStarted = false;

  /// Error codes that indicate a credential error (not network or other).
  static const _credentialErrorCodes = {
    'invalid-credential',
    'wrong-password',
    'user-not-found',
    'invalid-email',
  };

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();

    // Listen to cooldown stream
    _cooldownSub = _rateLimiter.cooldownStream.listen((remaining) {
      if (mounted) {
        setState(() => _cooldownRemaining = remaining);
      }
    });

    // Password change listener for strength indicator
    _passwordController.addListener(() {
      if (mounted) {
        setState(() => _passwordText = _passwordController.text);
      }
    });

    // Setup icon animation
    _iconAnimController = AnimationController(
      vsync: this,
      duration: AnimationConstants.loginIconScaleDuration,
    );

    _iconScale = CurvedAnimation(
      parent: _iconAnimController,
      curve: AnimationConstants.loginIconScaleCurve,
    );

    _iconGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 40,
      ),
    ]).animate(_iconAnimController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animStarted) {
      _animStarted = true;
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion) {
        _iconAnimController.value = 1.0;
      } else {
        _iconAnimController.forward();
      }
    }
  }

  // --- Functions ---
  Future<void> _signIn() async {
    // Basic validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AppToast.showError(context, 'Please enter both email and password.');
      return;
    }

    // Password minimum length check (FR-013)
    if (_passwordController.text.length < 6) {
      AppToast.showError(context, 'Password must be at least 6 characters.');
      return;
    }

    // Rate limit check
    if (_rateLimiter.isInCooldown) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use AuthService for sign-in (creates session, logs audit event)
      await _authService.signIn(
        _emailController.text,
        _passwordController.text,
      );

      // On success: reset rate limiter
      _rateLimiter.reset();

      // AuthGate StreamBuilder handles navigation — no Navigator.push needed
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        // Record failure for rate limiting (credential errors only)
        if (_credentialErrorCodes.contains(e.code)) {
          _rateLimiter.recordFailure();
        }
        AppErrorHandler.handleError(context, e);
      }
    } catch (e) {
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
    _iconAnimController.dispose();
    _cooldownSub?.cancel();
    _rateLimiter.dispose();
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
                  Center(
                    child: AnimatedBuilder(
                      animation: _iconAnimController,
                      builder: (context, child) {
                        final glowValue = _iconGlow.value;
                        return ScaleTransition(
                          scale: _iconScale,
                          child: Container(
                            padding: EdgeInsets.all(
                                context.responsivePadding(AppSpacing.lg)),
                            decoration: BoxDecoration(
                              color: AppColors.primaryWithLowOpacity,
                              shape: BoxShape.circle,
                              boxShadow: glowValue > 0
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                            alpha: glowValue *
                                                AnimationConstants
                                                    .loginIconGlowMaxOpacity),
                                        spreadRadius: glowValue *
                                            AnimationConstants
                                                .loginIconGlowMaxSpread,
                                        blurRadius: glowValue *
                                            AnimationConstants
                                                .loginIconGlowMaxBlur,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              Icons.bolt_rounded,
                              size: context.responsiveHeight(40),
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
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
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        color: AppColors.primary,
                        size: context.responsiveHeight(20),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
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
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        color: AppColors.primary,
                        size: context.responsiveHeight(20),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
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
              // Password strength indicator (FR-013, FR-014)
              PasswordStrengthIndicator(password: _passwordText),
              SizedBox(height: context.responsiveSpacing(AppSpacing.xxl)),
              // Cooldown notice
              if (_cooldownRemaining > 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Try again in ${_cooldownRemaining}s',
                        style: AppTypography.bodyStyle.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.responsiveSpacing(AppSpacing.md)),
              ],
              // Modern Login Button
              _isLoading
                  ? const AppLoading(variant: AppLoadingVariant.inline)
                  : AppButton(
                      label: 'SIGN IN',
                      onPressed: _cooldownRemaining > 0 ? null : _signIn,
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
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
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
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
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
