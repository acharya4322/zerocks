import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/shops/screens/shop_detail_screen.dart';
import '../features/scanner/screens/qr_scanner_screen.dart';
import '../features/upload/screens/upload_screen.dart';
import '../features/print_job/screens/job_tracking_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoading = authState.isLoading;
      final isOnAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/otp';

      // While loading auth state, don't redirect
      if (isLoading) return null;

      // Not logged in, and not on an auth page → go to login
      if (!isLoggedIn && !isOnAuthPage) return '/login';

      // Logged in and on login page → go to home
      if (isLoggedIn && state.matchedLocation == '/login') return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/shop/:shopId',
        builder: (context, state) {
          final shopId = state.pathParameters['shopId']!;
          return ShopDetailScreen(shopId: shopId);
        },
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/upload/:shopId',
        builder: (context, state) {
          final shopId = state.pathParameters['shopId']!;
          return UploadScreen(shopId: shopId);
        },
      ),
      GoRoute(
        path: '/job/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return JobTrackingScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
