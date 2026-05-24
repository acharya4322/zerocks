import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';

// ── Service Providers ────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

// ── Repository Providers ─────────────────────────────────
final printJobRepoProvider = Provider<PrintJobRepository>((ref) {
  return PrintJobRepository(
    ref.read(firestoreServiceProvider),
    ref.read(storageServiceProvider),
  );
});

final shopRepoProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.read(firestoreServiceProvider));
});

// ── Auth State ───────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// ── Shop Provider ────────────────────────────────────────
/// One-shot fetch of the shop for the current owner.
final shopProvider = FutureProvider<ShopModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return null;

  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getShopByOwner(user.uid);
});

// ── Shop Stream Provider (real-time updates) ─────────────
/// FIXED: Uses Firestore snapshots instead of polling.
/// Previously polled every 5 seconds, now uses real-time listeners.
final shopStreamProvider = StreamProvider<ShopModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(null);

  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamShopByOwner(user.uid);
});
