import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';

enum AuthState { idle, loading, success, error }

class AuthNotifier extends Notifier<AuthScreenState> {
  @override
  AuthScreenState build() => const AuthScreenState();

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(authState: AuthState.loading, errorMessage: '');

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(email: email, password: password);
      state = state.copyWith(authState: AuthState.success);
    } catch (e) {
      String message = 'Sign in failed. Please try again.';
      if (e.toString().contains('user-not-found')) {
        message = 'No account found with this email.';
      } else if (e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        message = 'Invalid email or password.';
      } else if (e.toString().contains('invalid-email')) {
        message = 'Please enter a valid email address.';
      } else if (e.toString().contains('too-many-requests')) {
        message = 'Too many attempts. Please try again later.';
      }
      state = state.copyWith(
        authState: AuthState.error,
        errorMessage: message,
      );
    }
  }

  void clearError() {
    state = state.copyWith(authState: AuthState.idle, errorMessage: '');
  }
}

class AuthScreenState {
  final AuthState authState;
  final String errorMessage;

  const AuthScreenState({
    this.authState = AuthState.idle,
    this.errorMessage = '',
  });

  AuthScreenState copyWith({
    AuthState? authState,
    String? errorMessage,
  }) {
    return AuthScreenState(
      authState: authState ?? this.authState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthScreenState>(AuthNotifier.new);
