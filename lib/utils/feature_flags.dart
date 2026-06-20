abstract final class FeatureFlags {
  static const bool enableBonusModule =
      bool.fromEnvironment('ENABLE_BONUS_MODULE');
}
