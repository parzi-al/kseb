import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/animation_constants.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import 'login_screen.dart';
import 'worker_home_screen.dart';

/// Branded splash screen displayed on every cold app launch.
///
/// Animation sequence:
/// 1. Lightning-bolt icon scales up (0→800ms)
/// 2. "KSEB" text slides up (800→1300ms)
/// 3. Hold until min duration (1500ms) AND auth resolved
/// 4. Cross-fade (400ms) to [LoginScreen] or [WorkerHomeScreen]
///
/// If auth takes longer than [AnimationConstants.splashMaxDuration],
/// a pulsing loading indicator is shown.
///
/// Respects reduce-motion accessibility setting via [respectMotion].
class SplashScreen extends StatefulWidget {
  /// If true, skips Firebase auth and provides test-only navigation.
  final bool testMode;

  /// If true (test only), simulates a slow auth that exceeds max duration.
  final bool simulateSlowAuth;

  const SplashScreen({
    super.key,
    this.testMode = false,
    this.simulateSlowAuth = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Single controller for the splash animation sequence (icon + text).
  late final AnimationController _sequenceController;
  late final Animation<double> _iconScale;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  /// Controller for the cross-fade out transition.
  late final AnimationController _crossFadeController;
  late final Animation<double> _crossFade;

  bool _authResolved = false;
  bool _showLoading = false;
  bool _isTransitioning = false;
  bool _sequenceStarted = false;
  Widget? _destinationScreen;

  @override
  void initState() {
    super.initState();

    final totalMs = AnimationConstants.splashMinDuration.inMilliseconds;
    final iconFrac =
        AnimationConstants.splashIconScaleDuration.inMilliseconds / totalMs;
    final textStart = iconFrac;
    final textEnd = textStart +
        AnimationConstants.splashTextSlideDuration.inMilliseconds / totalMs;

    // ── Sequence controller covers 0 → splashMinDuration ──────────
    _sequenceController = AnimationController(
      vsync: this,
      duration: AnimationConstants.splashMinDuration,
    );

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: Interval(0.0, iconFrac, curve: Curves.easeOutBack),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: Interval(textStart, textEnd, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: Interval(textStart, textEnd, curve: Curves.easeOutCubic),
      ),
    );

    _sequenceController.addStatusListener(_onSequenceComplete);

    // ── Cross-fade controller ─────────────────────────────────────
    _crossFadeController = AnimationController(
      vsync: this,
      duration: AnimationConstants.splashCrossFadeDuration,
    );
    _crossFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _crossFadeController, curve: Curves.easeInOut),
    );
    _crossFadeController.addStatusListener(_onCrossFadeComplete);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sequenceStarted) {
      _sequenceStarted = true;
      _start();
    }
  }

  // ── Lifecycle ───────────────────────────────────────────────────

  void _start() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      // Static frame — jump to end value immediately
      _sequenceController.value = 1.0;
      // _onSequenceComplete will fire synchronously
    } else {
      _sequenceController.forward();
    }

    // Resolve auth concurrently
    _resolveAuth();

    // Max-timeout loading indicator
    Future.delayed(AnimationConstants.splashMaxDuration, () {
      if (!mounted || _isTransitioning) return;
      if (!_authResolved) {
        setState(() => _showLoading = true);
      }
    });
  }

  void _onSequenceComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _tryTransition();
    }
  }

  void _onCrossFadeComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _navigateToDestination();
    }
  }

  // ── Auth ────────────────────────────────────────────────────────

  Future<void> _resolveAuth() async {
    if (widget.testMode) {
      if (widget.simulateSlowAuth) {
        await Future.delayed(
          AnimationConstants.splashMaxDuration +
              const Duration(milliseconds: 500),
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;
      _authResolved = true;
      _destinationScreen = const Scaffold(
        body: Center(child: Text('Test Destination')),
      );
      _tryTransition();
      return;
    }

    // Production
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _destinationScreen = const WorkerHomeScreen();
      } else {
        final authUser =
            await FirebaseAuth.instance.authStateChanges().first.timeout(
                  AnimationConstants.splashMaxDuration,
                  onTimeout: () => null,
                );
        _destinationScreen =
            authUser != null ? const WorkerHomeScreen() : const LoginScreen();
      }
    } catch (_) {
      _destinationScreen = const LoginScreen();
    }

    if (!mounted) return;
    _authResolved = true;
    _tryTransition();
  }

  // ── Transition ──────────────────────────────────────────────────

  void _tryTransition() {
    if (!_authResolved ||
        !_sequenceController.isCompleted ||
        _isTransitioning) {
      return;
    }
    _isTransitioning = true;

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _navigateToDestination();
    } else {
      _crossFadeController.forward();
    }
  }

  void _navigateToDestination() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _destinationScreen ?? const LoginScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _sequenceController.removeStatusListener(_onSequenceComplete);
    _crossFadeController.removeStatusListener(_onCrossFadeComplete);
    _sequenceController.dispose();
    _crossFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _crossFade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lightning bolt icon with scale animation
              ScaleTransition(
                scale: _iconScale,
                child: Icon(
                  Icons.flash_on,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // "KSEB" text with slide-up animation
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Text(
                    AnimationConstants.appName,
                    style: AppTypography.displayLargeStyle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              // Loading indicator
              if (_showLoading) ...[
                const SizedBox(height: AppSpacing.xl * 2),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
