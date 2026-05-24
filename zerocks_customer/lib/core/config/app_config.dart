/// Environment configuration for Zerocks apps.
///
/// Values are injected at compile time via `--dart-define`:
/// ```
/// flutter run --dart-define=ENV=production
/// flutter run --dart-define=USE_EMULATORS=true
/// ```
class AppConfig {
  AppConfig._();

  /// Current environment: 'development', 'staging', or 'production'.
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';

  /// Whether to use Firebase Emulators.
  static const bool useEmulators = bool.fromEnvironment(
    'USE_EMULATORS',
    defaultValue: false,
  );

  /// Emulator host — use 10.0.2.2 for Android emulator, localhost for others.
  static const String emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );

  static const int firestorePort = 8080;
  static const int authPort = 9099;
  static const int storagePort = 9199;
  static const int functionsPort = 5001;

  /// App version constraints (can be overridden by platform/config doc).
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxCopies = 100;
  static const int minCopies = 1;

  /// Job expiry duration.
  static const Duration jobExpiry = Duration(hours: 24);

  /// Signed URL expiry (must match Cloud Function).
  static const Duration signedUrlExpiry = Duration(minutes: 15);
}
