import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/logger.dart';

/// Wrapper around Firebase Cloud Messaging for push notifications.
/// Handles token management, permission requests, and message routing.
class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Request notification permissions (iOS/Web).
  /// On Android 13+, this shows the system permission dialog.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final granted = settings.authorizationStatus ==
        AuthorizationStatus.authorized;
    ZLogger.info(
      'Notification permission: ${settings.authorizationStatus.name}',
      tag: 'FCM',
    );
    return granted;
  }

  /// Get the FCM device token for this device.
  /// Returns null if permissions haven't been granted.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      ZLogger.error('Failed to get FCM token', error: e, tag: 'FCM');
      return null;
    }
  }

  /// Listen for token refresh events.
  /// Call this on app start and update the token in Firestore.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Listen for foreground messages.
  Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage;

  /// Handle background messages.
  /// Must be a top-level function (not a method).
  static void registerBackgroundHandler(
    Future<void> Function(RemoteMessage) handler,
  ) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  /// Get the initial message that opened the app (cold start from notification).
  Future<RemoteMessage?> getInitialMessage() {
    return _messaging.getInitialMessage();
  }

  /// Listen for messages that opened the app (app was in background).
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Subscribe to a topic (e.g., 'shop_{shopId}' for shop-specific notifications).
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    ZLogger.info('Subscribed to topic: $topic', tag: 'FCM');
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    ZLogger.info('Unsubscribed from topic: $topic', tag: 'FCM');
  }
}
