import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

/// Repository for authentication and user profile operations.
class AuthRepository {
  final AuthService _auth;
  final FirestoreService _firestore;

  AuthRepository(this._auth, this._firestore);

  /// Current auth state stream.
  Stream<User?> get authStateChanges => _auth.authStateChanges;

  /// Current user (synchronous).
  User? get currentUser => _auth.currentUser;

  /// Send OTP for phone authentication.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    int? resendToken,
  }) {
    return _auth.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onAutoVerified: onAutoVerified,
      resendToken: resendToken,
    );
  }

  /// Verify OTP and sign in. Creates user profile if first login.
  Future<UserCredential> verifyOtpAndSignIn({
    required String verificationId,
    required String otp,
  }) async {
    final credential = await _auth.verifyOtp(
      verificationId: verificationId,
      otp: otp,
    );

    // Create Firestore profile if new user
    if (credential.additionalUserInfo?.isNewUser ?? false) {
      final user = credential.user!;
      await _firestore.createUser(UserModel(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        createdAt: DateTime.now(),
      ));
      ZLogger.info('New user profile created: ${user.uid}', tag: 'AuthRepo');
    }

    return credential;
  }

  /// Sign in with email/password (for shop owners and admins).
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmail(email: email, password: password);
  }

  /// Get user profile from Firestore.
  Future<UserModel?> getUserProfile(String uid) {
    return _firestore.getUser(uid);
  }

  /// Sign out.
  Future<void> signOut() {
    ZLogger.info('User signed out', tag: 'AuthRepo');
    return _auth.signOut();
  }
}
