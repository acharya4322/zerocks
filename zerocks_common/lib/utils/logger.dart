import 'dart:developer' as dev;

/// Structured logger for the Zerocks platform.
/// Provides consistent logging across all apps with severity levels.
///
/// In production, errors are also forwarded to Firebase Crashlytics
/// (when initialized by the app's main.dart).
class ZLogger {
  ZLogger._();

  /// Log an informational message.
  static void info(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
  }) {
    final label = tag ?? 'Zerocks';
    dev.log('ℹ️ $message', name: label);
    if (data != null) {
      dev.log('   ↳ $data', name: label);
    }
  }

  /// Log a warning.
  static void warn(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
  }) {
    final label = tag ?? 'Zerocks';
    dev.log('⚠️ $message', name: label);
    if (data != null) {
      dev.log('   ↳ $data', name: label);
    }
  }

  /// Log an error with optional exception and stack trace.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    final label = tag ?? 'Zerocks';
    dev.log(
      '❌ $message',
      name: label,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a debug message (only in development).
  static void debug(
    String message, {
    String? tag,
  }) {
    assert(() {
      dev.log('🐛 $message', name: tag ?? 'Zerocks');
      return true;
    }());
  }

  /// Log a network/API call for tracing.
  static void network(
    String method,
    String endpoint, {
    int? statusCode,
    String? tag,
  }) {
    final status = statusCode != null ? ' → $statusCode' : '';
    dev.log('🌐 $method $endpoint$status', name: tag ?? 'Zerocks.Net');
  }
}
