import 'dart:async';
import 'package:flutter/foundation.dart';

/// Manages inactivity timer for auto-logout (FR-011, FR-012).
///
/// Uses a simple restartable [Timer]. Each call to [resetTimer] cancels
/// the existing timer and starts a new one. When the timer fires,
/// the [onTimeout] callback is invoked (typically triggers sign-out).
///
/// Wraps only the authenticated widget subtree — no timer on login screen.
class IdleTimeoutService {
  Timer? _idleTimer;
  Duration _timeoutDuration = const Duration(minutes: 15);
  VoidCallback? _onTimeout;
  bool _isRunning = false;

  /// Whether the idle timeout timer is currently active.
  bool get isRunning => _isRunning;

  /// Current timeout duration.
  Duration get timeoutDuration => _timeoutDuration;

  /// Start the idle timeout timer.
  ///
  /// [timeoutMinutes] is the inactivity threshold in minutes.
  /// [onTimeout] is called when the timer fires.
  void start({
    required int timeoutMinutes,
    required VoidCallback onTimeout,
  }) {
    _timeoutDuration = Duration(minutes: timeoutMinutes);
    _onTimeout = onTimeout;
    _isRunning = true;
    _restartTimer();
  }

  /// Reset the timer (called on user interaction).
  ///
  /// Cancels the existing timer and starts a new one with the
  /// full timeout duration. No-op if not running.
  void resetTimer() {
    if (!_isRunning) return;
    _restartTimer();
  }

  /// Pause the timer (e.g., when app goes to background).
  void pause() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// Resume the timer (e.g., when app returns to foreground).
  ///
  /// Starts a fresh timer with the full timeout duration.
  void resume() {
    if (!_isRunning) return;
    _restartTimer();
  }

  /// Stop the idle timeout completely.
  void stop() {
    _isRunning = false;
    _idleTimer?.cancel();
    _idleTimer = null;
    _onTimeout = null;
  }

  void _restartTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_timeoutDuration, () {
      if (_isRunning && _onTimeout != null) {
        debugPrint('IdleTimeoutService: Idle timeout reached');
        _onTimeout!();
      }
    });
  }

  /// Clean up resources.
  void dispose() {
    stop();
  }
}
