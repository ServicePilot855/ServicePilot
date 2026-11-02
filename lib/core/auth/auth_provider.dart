import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/features/auth/mock/mock_auth_service.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';

/// Provides the single instance of [MockAuthService] for the app.
final mockAuthServiceProvider = Provider<MockAuthService>(
  (_) => MockAuthService(),
);

/// Manages global authentication state via Riverpod [Notifier].
///
/// Screens should watch [authProvider] to react to state changes.
class AuthNotifier extends Notifier<AuthState> {
  MockAuthService get _auth => ref.read(mockAuthServiceProvider);

  @override
  AuthState build() => const AuthStateUnauthenticated();

  // ── Helpers ───────────────────────────────────────────────────────────────

  UserModel? get currentUser {
    final s = state;
    return s is AuthStateAuthenticated ? s.user : null;
  }

  bool get isAuthenticated => state is AuthStateAuthenticated;

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

  void logout() {
    state = const AuthStateUnauthenticated();
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
  }) async {
    state = const AuthStateLoading();
    try {
      await _auth.registerTechnician(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        serviceArea: serviceArea,
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
  }) async {
    state = const AuthStateLoading();
    try {
      await _auth.registerCompany(
        ownerFullName: ownerFullName,
        email: email,
        phoneNumber: phoneNumber,
        companyName: companyName,
        serviceArea: serviceArea,
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
  }) async {
    state = const AuthStateLoading();
    try {
      await _auth.activateTechnicianAccount(
        token: token,
        fullName: fullName,
        password: password,
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
