import 'package:service_pilot/features/auth/models/user_model.dart';

/// Sealed class representing the three possible authentication states.
sealed class AuthState {
  const AuthState();
}

/// No user is currently authenticated.
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// An async operation (login, register) is in progress.
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// A user is authenticated and active.
class AuthStateAuthenticated extends AuthState {
  final UserModel user;
  const AuthStateAuthenticated(this.user);
}

/// An authentication error occurred.
class AuthStateError extends AuthState {
  final String message;
  const AuthStateError(this.message);
}
