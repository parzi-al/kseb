import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/idle_timeout_service.dart';
import '../utils/animation_constants.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'worker_home_screen.dart';

/// Root auth-driven navigation widget (FR-009).
///
/// Uses `StreamBuilder<User?>` on `FirebaseAuth.authStateChanges()` to
/// declaratively switch between [LoginScreen] and [WorkerHomeScreen].
///
/// On cold start, shows [SplashScreen] for the minimum animation duration
/// before transitioning. Subsequent auth changes skip the splash.
///
/// When the user is authenticated, wraps the authenticated subtree
/// in a [Listener] for idle timeout detection (FR-011).
class AuthGate extends StatefulWidget {
  /// The [AuthService] instance to use. If null, creates a default one.
  final AuthService? authService;

  /// For testing: override the auth stream.
  final Stream<User?>? authStream;

  /// For testing: skip the initial splash delay.
  final bool skipSplash;

  const AuthGate({
    super.key,
    this.authService,
    this.authStream,
    this.skipSplash = false,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService;
  final IdleTimeoutService _idleTimeoutService = IdleTimeoutService();

  bool _isInitialLoad = true;
  bool _splashComplete = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();

    if (widget.skipSplash) {
      _splashComplete = true;
      _isInitialLoad = false;
    } else {
      // Show splash for minimum duration, then switch
      Future.delayed(AnimationConstants.splashMinDuration, () {
        if (mounted) {
          setState(() {
            _splashComplete = true;
          });
        }
      });
    }

    // Initialize idle timeout with default; will update from Firestore
    _initIdleTimeout();
  }

  Future<void> _initIdleTimeout() async {
    try {
      final minutes = await _authService.getIdleTimeoutMinutes();
      _idleTimeoutService.start(
        timeoutMinutes: minutes,
        onTimeout: _onIdleTimeout,
      );
    } catch (e) {
      // Fallback: use default 15 minutes
      _idleTimeoutService.start(
        timeoutMinutes: 15,
        onTimeout: _onIdleTimeout,
      );
    }
  }

  void _onIdleTimeout() {
    _authService.signOut(reason: 'idle_timeout');
  }

  void _onUserInteraction() {
    _idleTimeoutService.resetTimer();
  }

  @override
  void dispose() {
    _idleTimeoutService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.authStream ?? _authService.authStateChanges;

    return StreamBuilder<User?>(
      stream: stream,
      builder: (context, snapshot) {
        // Initial load: show splash while waiting for both splash animation
        // and first auth state emission
        if (_isInitialLoad) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_splashComplete) {
            return const SplashScreen();
          }

          // Once we have data OR splash is complete, transition
          if (snapshot.hasData || _splashComplete) {
            // Mark initial load as done — subsequent auth changes skip splash
            _isInitialLoad = false;
          } else if (!_splashComplete) {
            return const SplashScreen();
          }
        }

        // User is authenticated → show home with idle timeout detection
        if (snapshot.hasData && snapshot.data != null) {
          return Listener(
            onPointerDown: (_) => _onUserInteraction(),
            child: const WorkerHomeScreen(),
          );
        }

        // User is not authenticated → show login
        // Stop idle timeout when not authenticated
        _idleTimeoutService.pause();
        return const LoginScreen();
      },
    );
  }
}
