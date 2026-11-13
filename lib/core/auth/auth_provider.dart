import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_service.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/auth/firebase_auth_service.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';

/// Provides the active [IAuthService] implementation via [FirebaseAuthService].
final authServiceProvider = Provider<IAuthService>(
  (_) => FirebaseAuthService(),
);

/// Convenient selector provider for the current authenticated user.
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthStateAuthenticated ? authState.user : null;
});

/// Manages global authentication state via Riverpod [Notifier].
///
/// Screens should watch [authProvider] to react to state changes.
class AuthNotifier extends Notifier<AuthState> {
  IAuthService get _auth => ref.read(authServiceProvider);

  @override
  AuthState build() => const AuthStateUnauthenticated();

  // ── Helpers ───────────────────────────────────────────────────────────────

  UserModel? get currentUser {
    final s = state;
    return s is AuthStateAuthenticated ? s.user : null;
  }

  bool get isAuthenticated => state is AuthStateAuthenticated;

  /// Restores any existing authenticated Firebase session on app startup.
  Future<void> checkAuthStatus() async {
    try {
      final user = await _auth.getCurrentUser();
      if (user != null) {
        state = AuthStateAuthenticated(user);
      }
    } catch (_) {
      // Remain unauthenticated on error
    }
  }

  // ── Login / Logout ────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    state = const AuthStateLoading();
    try {
      final user = await _auth.login(email, password);
      state = AuthStateAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
    } catch (_) {
      state = const AuthStateError('An unexpected error occurred.');
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthStateLoading();
    try {
      final user = await _auth.signInWithGoogle();
      state = AuthStateAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
    } catch (_) {
      state = const AuthStateError('Google sign in failed. Please try again.');
    }
  }

  Future<void> logout() async {
    try {
      await _auth.logout();
    } finally {
      state = const AuthStateUnauthenticated();
    }
  }

  void clearError() {
    if (state is AuthStateError) {
      state = const AuthStateUnauthenticated();
    }
  }

  // ── Registration ──────────────────────────────────────────────────────────

  Future<bool> registerCustomer({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    state = const AuthStateLoading();
    try {
      await _auth.registerCustomer(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );
      state = const AuthStateUnauthenticated();
      return true;
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
      return false;
    } catch (_) {
      state = const AuthStateError('Registration failed. Please try again.');
      return false;
    }
  }

  Future<bool> registerTechnician({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String serviceArea,
    required String password,
  }) async {
    state = const AuthStateLoading();
    try {
      await _auth.registerTechnician(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        serviceArea: serviceArea,
        password: password,
      );
      state = const AuthStateUnauthenticated();
      return true;
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
      return false;
    } catch (_) {
      state = const AuthStateError('Registration failed. Please try again.');
      return false;
    }
  }

  Future<bool> registerCompany({
    required String ownerFullName,
    required String email,
    required String phoneNumber,
    required String companyName,
    required String serviceArea,
    String? password,
  }) async {
    state = const AuthStateLoading();
    try {
      await _auth.registerCompany(
        ownerFullName: ownerFullName,
        email: email,
        phoneNumber: phoneNumber,
        companyName: companyName,
        serviceArea: serviceArea,
        password: password,
      );
      state = const AuthStateUnauthenticated();
      return true;
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
      return false;
    } catch (_) {
      state = const AuthStateError('Registration failed. Please try again.');
      return false;
    }
  }

  Future<bool> activateTechnicianAccount({
    required String token,
    required String fullName,
    required String password,
    String? email,
  }) async {
    state = const AuthStateLoading();
    try {
      await _auth.activateTechnicianAccount(
        token: token,
        fullName: fullName,
        password: password,
        email: email,
      );
      state = const AuthStateUnauthenticated();
      return true;
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
      return false;
    } catch (_) {
      state = const AuthStateError('Activation failed. Please try again.');
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    state = const AuthStateLoading();
    try {
      await _auth.requestPasswordReset(email);
      state = const AuthStateUnauthenticated();
      return true;
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
      return false;
    } catch (_) {
      state = const AuthStateError('Could not send reset email.');
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = const AuthStateLoading();
    try {
      await _auth.resetPassword(token: token, newPassword: newPassword);
      state = const AuthStateUnauthenticated();
      return true;
    } on AuthException catch (e) {
      state = AuthStateError(e.message);
      return false;
    } catch (_) {
      state = const AuthStateError('Password reset failed.');
      return false;
    }
  }
}

/// The global auth provider — watch this in any screen that needs auth state.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
