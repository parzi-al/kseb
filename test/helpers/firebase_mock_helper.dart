import 'package:flutter_test/flutter_test.dart';

// Re-export the official Firebase Core mock setup from the platform interface.
// This uses the Pigeon-based TestFirebaseCoreHostApi approach required by
// firebase_core_platform_interface ≥ 5.x / firebase_core ≥ 3.x.
export 'package:firebase_core_platform_interface/test.dart'
    show setupFirebaseCoreMocks;
