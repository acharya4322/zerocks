import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../services/admin_service.dart';

// ── Service Providers ────────────────────────────────────

final firestoreServiceProvider = Provider<FirestoreService>(
  (_) => FirestoreService(),
);

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.read(firestoreServiceProvider));
});

// ── Repository Providers ─────────────────────────────────

final shopRepoProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.read(firestoreServiceProvider));
});

final userRepoProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(firestoreServiceProvider));
});

// ── Auth State ───────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ── Platform Stats (real-time) ───────────────────────────

final platformStatsProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamPlatformStats();
});
