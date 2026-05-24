import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';

// ── Service Providers ────────────────────────────────────

/// Provides the singleton [AuthService] instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provides the singleton [FirestoreService] instance.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Provides the singleton [StorageService] instance.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// ── Repository Providers ─────────────────────────────────

/// Provides the [AuthRepository] instance.
final authRepoProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(authServiceProvider),
    ref.read(firestoreServiceProvider),
  );
});

/// Provides the [PrintJobRepository] instance.
final printJobRepoProvider = Provider<PrintJobRepository>((ref) {
  return PrintJobRepository(
    ref.read(firestoreServiceProvider),
    ref.read(storageServiceProvider),
  );
});

/// Provides the [ShopRepository] instance.
final shopRepoProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.read(firestoreServiceProvider));
});

/// Provides the [UserRepository] instance.
final userRepoProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(firestoreServiceProvider));
});

// ── Auth State ───────────────────────────────────────────

/// Watches Firebase auth state changes.
/// Emits the current [User] or null if signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});
