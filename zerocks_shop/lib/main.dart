import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:zerocks_common/zerocks_common.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'providers/app_providers.dart';
import 'firebase_options.dart';

/// Top-level background message handler (must be top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ZLogger.info(
    'Background FCM: ${message.notification?.title}',
    tag: 'FCM',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable right-click context menu on web for security
  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: ZerocksShopApp()));
}

class ZerocksShopApp extends ConsumerStatefulWidget {
  const ZerocksShopApp({super.key});

  @override
  ConsumerState<ZerocksShopApp> createState() => _ZerocksShopAppState();
}

class _ZerocksShopAppState extends ConsumerState<ZerocksShopApp> {
  @override
  void initState() {
    super.initState();
    _setupFcm();
  }

  Future<void> _setupFcm() async {
    final messaging = MessagingService();

    // Request permission
    await messaging.requestPermission();

    // Get and store FCM token
    final token = await messaging.getToken();
    if (token != null) {
      _updateShopFcmToken(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen(_updateShopFcmToken);

    // Handle foreground messages (show snackbar)
    messaging.onForegroundMessage.listen((message) {
      final notification = message.notification;
      if (notification != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.body ?? 'New notification'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Navigate to the job if jobId is in data
                final jobId = message.data['jobId'] as String?;
                if (jobId != null) {
                  // TODO: Navigate to job detail
                }
              },
            ),
          ),
        );
      }
    });
  }

  void _updateShopFcmToken(String token) {
    final shopAsync = ref.read(shopStreamProvider);
    final shop = shopAsync.value;
    if (shop != null) {
      ref.read(firestoreServiceProvider).updateShopFcmToken(shop.id, token);
      ZLogger.info('Shop FCM token updated', tag: 'FCM');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: kIsWeb ? 'Zerocks Shop Dashboard' : 'Zerocks Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
