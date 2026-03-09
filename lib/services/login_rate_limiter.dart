import 'dart:async';

/// Progressive rate limiter for failed login attempts (FR-015, FR-016, FR-017).
///
/// State is held in-memory only — resets on app restart (per spec).
///
/// Cooldown thresholds:
/// - 3 failures → 5 seconds
/// - 5 failures → 15 seconds
/// - 8+ failures → 30 seconds
class LoginRateLimiter {
  /// Sorted thresholds: {failedAttempts: cooldownSeconds}.
  static const Map<int, int> _thresholds = {
    3: 5,
    5: 15,
    8: 30,
  };

  int _failedAttempts = 0;
  int _remainingSeconds = 0;
  Timer? _cooldownTimer;

  /// Stream controller for countdown ticks (emits remaining seconds).
  final _cooldownController = StreamController<int>.broadcast();

  /// Number of consecutive failed login attempts.
  int get failedAttempts => _failedAttempts;

  /// Whether a cooldown is currently active.
  bool get isInCooldown => _remainingSeconds > 0;

  /// Remaining seconds in the current cooldown period.
  int get remainingSeconds => _remainingSeconds;

  /// Stream that emits remaining seconds each tick during cooldown.
  Stream<int> get cooldownStream => _cooldownController.stream;

  /// Record a failed login attempt.
  ///
  /// Increments the failure counter and starts a cooldown if a threshold
  /// is reached. Only call this for credential errors (wrong-password,
  /// user-not-found, invalid-credential), NOT for network errors.
  void recordFailure() {
    _failedAttempts++;
    _startCooldownIfNeeded();
  }

  /// Reset the rate limiter (on successful login).
  void reset() {
    _failedAttempts = 0;
    _remainingSeconds = 0;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _cooldownController.add(0);
  }

  /// Find the cooldown duration (seconds) for the current failure count.
  ///
  /// Returns 0 if no threshold is met.
  int _getCooldownSeconds() {
    int cooldown = 0;
    for (final entry in _thresholds.entries) {
      if (_failedAttempts >= entry.key) {
        cooldown = entry.value;
      }
    }
    return cooldown;
  }

  void _startCooldownIfNeeded() {
    final cooldownSecs = _getCooldownSeconds();
    if (cooldownSecs <= 0) return;

    // Cancel any existing timer
    _cooldownTimer?.cancel();
    _remainingSeconds = cooldownSecs;
    _cooldownController.add(_remainingSeconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _cooldownController.add(_remainingSeconds);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _cooldownTimer = null;
      }
    });
  }

  /// Clean up resources.
  void dispose() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _cooldownController.close();
  }
}
