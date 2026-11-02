import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';

/// Exception thrown when mock authentication fails.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// In-memory mock authentication service.
///
/// This replaces a real API/backend during Sprint 1.
/// All operations run with a simulated network delay.
class MockAuthService {
  static const _mockInviteToken = 'INVITE-2024-MOCK';
  static const _mockPassword = 'password123';
  static const _fakeDelayMs = 1200;

  // Mutable in-memory user list — starts with seed data.
  static final List<UserModel> _users = [
    const UserModel(
      id: '1',
      fullName: 'Dara Sok',
      email: 'customer@test.com',
      phoneNumber: '+85512345678',
      role: AppRole.homeowner,
      status: 'active',
    ),
    const UserModel(
      id: '2',
      fullName: 'Virak Chan',
      email: 'technician@test.com',
      phoneNumber: '+85587654321',
      role: AppRole.independentProvider,
      status: 'pending_verification',
    ),
    const UserModel(
      id: '3',
      fullName: 'Sophea Lim',
      email: 'company@test.com',
      phoneNumber: '+85511223344',
      role: AppRole.company,
      status: 'pending_verification',
    ),
    const UserModel(
      id: '4',
      fullName: 'Borey Nhem',
      email: 'tech@company.com',
      phoneNumber: '+85599887766',
      role: AppRole.companyTechnician,
      status: 'active',
      companyId: 'c1',
      companyName: 'Phnom Penh Fix Co.',
    ),
    const UserModel(
      id: '5',
      fullName: 'Admin User',
      email: 'admin@servicepilot.com',
      phoneNumber: '+85500000001',
      role: AppRole.admin,
      status: 'active',
    ),
  ];

  int _nextId = 6;

  /// Simulates a network round-trip delay.
  Future<void> _delay() =>
      Future.delayed(const Duration(milliseconds: _fakeDelayMs));

  // ── Authentication ────────────────────────────────────────────────────────

  /// Finds a user by [email] and validates the [password].
  ///
  /// Throws [AuthException] if credentials are invalid.
  Future<UserModel> login(String email, String password) async {
    await _delay();
    final user = _users.where((u) => u.email == email).firstOrNull;
    if (user == null || password != _mockPassword) {
      throw const AuthException('Invalid email or password.');
    }
    return user;
  }

  Future<void> logout() async {
    // Nothing to clear in mock — state lives in Riverpod.
  }

  // ── Registration ─────────────────────────────────────────────────────────

  /// Creates a new homeowner account.
  Future<UserModel> registerCustomer({
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    await _delay();
    _assertEmailAvailable(email);
    final user = UserModel(
      id: '${_nextId++}',
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      role: AppRole.homeowner,
      status: 'active',
    );
    _users.add(user);
    return user;
  }

  /// Creates a new independent technician account (pending approval).
  Future<UserModel> registerTechnician({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String serviceArea,
  }) async {
    await _delay();
    _assertEmailAvailable(email);
    final user = UserModel(
      id: '${_nextId++}',
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      role: AppRole.independentProvider,
      status: 'pending_verification',
    );
    _users.add(user);
    return user;
  }

  /// Creates a new company account (pending approval).
  Future<UserModel> registerCompany({
    required String ownerFullName,
    required String email,
    required String phoneNumber,
    required String companyName,
    required String serviceArea,
  }) async {
    await _delay();
    _assertEmailAvailable(email);
    final user = UserModel(
      id: '${_nextId++}',
      fullName: ownerFullName,
      email: email,
      phoneNumber: phoneNumber,
      role: AppRole.company,
      status: 'pending_verification',
      companyName: companyName,
    );
    _users.add(user);
    return user;
  }

  // ── Technician Activation ─────────────────────────────────────────────────

  /// Validates a company invite token.
  ///
  /// Returns `true` if the token is the known mock token.
  bool validateInviteToken(String token) => token == _mockInviteToken;

  /// Activates a company technician account using an invite token.
  ///
  /// Throws [AuthException] if the token is invalid.
  Future<UserModel> activateTechnicianAccount({
    required String token,
    required String fullName,
    required String password,
  }) async {
    await _delay();
    if (token != _mockInviteToken) {
      throw const AuthException('Invalid or expired invitation token.');
    }
    final user = UserModel(
      id: '${_nextId++}',
      fullName: fullName,
      email: 'tech.activated@company.com',
      phoneNumber: '+85500000099',
      role: AppRole.companyTechnician,
      status: 'active',
      companyId: 'c1',
      companyName: 'Phnom Penh Fix Co.',
    );
    _users.add(user);
    return user;
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  /// Simulates sending a password-reset email.
  Future<bool> requestPasswordReset(String email) async {
    await _delay();
    // In production this triggers a backend email send.
    // ignore: avoid_print
    print('[MockAuth] Password reset requested for $email');
    return true;
  }

  /// Simulates resetting a password with a token.
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _delay();
    // ignore: avoid_print
    print('[MockAuth] Password reset with token=$token');
    return true;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _assertEmailAvailable(String email) {
    final exists = _users.any((u) => u.email == email);
    if (exists) {
      throw const AuthException(
          'An account with this email already exists.');
    }
  }
}
