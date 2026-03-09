import 'package:flutter/material.dart';

import '../utils/animation_constants.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

/// Branded splash screen displayed during cold app launch.
///
/// This is now a **pure animation widget** — it has no auth logic.
/// Auth state is managed by [AuthGate] which renders this widget
/// during the initial loading period.
///
/// Animation sequence:
/// 1. Lightning-bolt icon scales up (0→800ms)
/// 2. "KSEB" text slides up (800→1300ms)
///
/// Respects reduce-motion accessibility setting via [respectMotion].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Single controller for the splash animation sequence (icon + text).
  late final AnimationController _sequenceController;
  late final Animation<double> _iconScale;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  bool _sequenceStarted = false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sequenceStarted) {
      _sequenceStarted = true;
      _start();
    }
  }

  void _start() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      // Static frame — jump to end value immediately
      _sequenceController.value = 1.0;
    } else {
      _sequenceController.forward();
    }
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
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
          ],
        ),
      ),
    );
  }
}
