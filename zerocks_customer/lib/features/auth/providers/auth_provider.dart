import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

// ── Auth State ────────────────────────────────────────────

enum AuthStatus {
  idle,
  sendingOtp,
  otpSent,
  verifying,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? verificationId;
  final int? resendToken;
  final String? errorMessage;
  final String phoneNumber;

  const AuthState({
    this.status = AuthStatus.idle,
    this.verificationId,
    this.resendToken,
    this.errorMessage,
    this.phoneNumber = '',
  });

  AuthState copyWith({
    AuthStatus? status,
    String? verificationId,
    int? resendToken,
    String? errorMessage,
    String? phoneNumber,
  }) {
    return AuthState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      errorMessage: errorMessage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;
  late final FirestoreService _firestoreService;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    _firestoreService = ref.watch(firestoreServiceProvider);
    return const AuthState();
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      status: AuthStatus.sendingOtp,
      phoneNumber: phoneNumber,
      errorMessage: null,
    );

    try {
      await _authService.sendOtp(
        phoneNumber: phoneNumber,
        resendToken: state.resendToken,
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(
            status: AuthStatus.otpSent,
            verificationId: verificationId,
            resendToken: resendToken,
          );
        },
        onError: (error) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: error.message ?? 'Failed to send OTP',
          );
        },
        onAutoVerified: (credential) async {
          state = state.copyWith(status: AuthStatus.verifying);
          try {
            final userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);
            await _ensureUserDocument(userCredential.user!);
            state = state.copyWith(status: AuthStatus.authenticated);
          } catch (e) {
            state = state.copyWith(
              status: AuthStatus.error,
              errorMessage: 'Auto-verification failed: ${e.toString()}',
            );
          }
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'No verification ID found. Please resend OTP.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.verifying, errorMessage: null);

    try {
      final userCredential = await _authService.verifyOtp(
        verificationId: state.verificationId!,
        otp: otp,
      );
      await _ensureUserDocument(userCredential.user!);
      state = state.copyWith(status: AuthStatus.authenticated);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message ?? 'Invalid OTP. Please try again.',
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Verification failed: ${e.toString()}',
      );
    }
  }

  Future<void> _ensureUserDocument(User user) async {
    final existing = await _firestoreService.getUser(user.uid);
    if (existing == null) {
      final newUser = UserModel(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? state.phoneNumber,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUser(newUser);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState();
  }

  void resetError() {
    state = state.copyWith(
      status: state.verificationId != null
          ? AuthStatus.otpSent
          : AuthStatus.idle,
      errorMessage: null,
    );
  }
}

// ── Provider ──────────────────────────────────────────────

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
