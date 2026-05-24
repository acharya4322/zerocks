import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

// Uncomment after adding firebase_crashlytics to pubspec.yaml:
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ── Crashlytics (uncomment after adding dependency) ──
  // if (AppConfig.isProduction) {
  //   FlutterError.onError =
  //       FirebaseCrashlytics.instance.recordFlutterFatalError;
  //   PlatformDispatcher.instance.onError = (error, stack) {
  //     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //     return true;
  //   };
  // }

  // ── Firebase Emulators (development only) ──
  if (AppConfig.useEmulators) {
    // Uncomment these after importing firebase packages:
    // import 'package:cloud_firestore/cloud_firestore.dart';
    // import 'package:firebase_auth/firebase_auth.dart';
    // import 'package:firebase_storage/firebase_storage.dart';
    //
    // FirebaseFirestore.instance.useFirestoreEmulator(
    //   AppConfig.emulatorHost, AppConfig.firestorePort);
    // await FirebaseAuth.instance.useAuthEmulator(
    //   AppConfig.emulatorHost, AppConfig.authPort);
    // await FirebaseStorage.instance.useStorageEmulator(
    //   AppConfig.emulatorHost, AppConfig.storagePort);
    debugPrint('🔧 Firebase Emulators enabled');
  }

  runApp(const ProviderScope(child: ZerocksApp()));
}

class ZerocksApp extends ConsumerWidget {
  const ZerocksApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
