import 'package:service_pilot/features/auth/models/user_model.dart';

/// Exception thrown when an authentication or registration operation fails.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Abstract contract for authentication and user account services.
///
/// Both [MockAuthService] (Sprint 1 prototype) and future `AuthApiService`
/// (Node.js/Express + PostgreSQL backend in SCRUM-67) implement this interface.
abstract class IAuthService {
  /// Returns the currently authenticated user, or null if unauthenticated.
  Future<UserModel?> getCurrentUser();

  /// Authenticates a user with email and password.
  Future<UserModel> login(String email, String password);

  /// Authenticates or registers a customer via Google Auth Provider.
  Future<UserModel> signInWithGoogle();

  /// Clears the authenticated session.
  Future<void> logout();

  /// Registers a customer (homeowner) account.
  Future<UserModel> registerCustomer({
    required String fullName,
    required String email,
    required String phoneNumber,
    String? password,
  });

  /// Registers an independent technician account (status: pending_verification).
  Future<UserModel> registerTechnician({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String serviceArea,
    required String password,
  });

  /// Registers a service company account (status: pending_verification).
  Future<UserModel> registerCompany({
    required String ownerFullName,
    required String email,
    required String phoneNumber,
    required String companyName,
    required String serviceArea,
    String? password,
  });

  /// Simulates/sends a password-reset request for the given email.
  Future<bool> requestPasswordReset(String email);

  /// Resets a password using a valid reset token.
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Validates a company invite token.
  bool validateInviteToken(String token);

  /// Activates an invited company technician account using an invite token.
  Future<UserModel> activateTechnicianAccount({
    required String token,
    required String fullName,
    required String password,
  });
}
