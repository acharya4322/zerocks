/// Environment configuration for Zerocks Shop app.
///
/// Values are injected at compile time via `--dart-define`:
/// ```
/// flutter run --dart-define=ENV=production
/// flutter run --dart-define=USE_EMULATORS=true
/// ```
class AppConfig {
  AppConfig._();

  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

  static const bool useEmulators = bool.fromEnvironment(
    'USE_EMULATORS',
    defaultValue: false,
  );

  static const String emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  static const int firestorePort = 8080;
  static const int authPort = 9099;
  static const int storagePort = 9199;
  static const int functionsPort = 5001;
}
