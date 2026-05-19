import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

/// Utility to determine if Firebase is available on the current platform
class FirebaseAvailability {
  /// Check if Firebase is available on this platform
  static bool get isAvailable {
    // Firebase is available on Android, iOS, and Web
    // Windows doesn't have Firebase C++ SDK support
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Get a user-friendly message about platform limitations
  static String get platformMessage {
    if (!isAvailable && defaultTargetPlatform == TargetPlatform.windows) {
      return 'This app is running on Windows.\n\n'
          'Firebase features are not available on Windows platforms.\n\n'
          'Please use the mobile app (Android/iOS) or web version for full functionality.';
    }
    if (!isAvailable) {
      return 'Firebase is not available on this platform.';
    }
    return '';
  }
}
