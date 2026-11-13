import 'package:service_pilot/core/auth/auth_service.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';

/// In-memory mock authentication service.
///
/// Implements [IAuthService] to replace a real API/backend during Sprint 1.
/// All operations run with a simulated network delay.
class MockAuthService implements IAuthService {
  static const _mockInviteToken = 'INVITE-2024-MOCK';
  static const _mockPassword = 'password123';
  static const _fakeDelayMs = 1200;

  static final Map<String, String> _userPasswords = {};

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
      serviceArea: 'Toul Kork, Phnom Penh',
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
  UserModel? _currentUser;

  /// Simulates a network round-trip delay.
  Future<void> _delay() =>
      Future.delayed(const Duration(milliseconds: _fakeDelayMs));

  // ── Authentication ────────────────────────────────────────────────────────

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  /// Finds a user by [email] and validates the [password].
  ///
  /// Throws [AuthException] if credentials are invalid.
  @override
  Future<UserModel> login(String email, String password) async {
    await _delay();
    final cleanEmail = email.trim().toLowerCase();
    final user = _users.where((u) => u.email.toLowerCase() == cleanEmail).firstOrNull;
    final expectedPassword = _userPasswords[cleanEmail] ?? _mockPassword;
    if (user == null || password != expectedPassword) {
      throw const AuthException('Invalid email or password.');
    }
    _currentUser = user;
    return user;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await _delay();
    final user = _users.first; // Dara Sok (Customer)
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  // ── Registration ─────────────────────────────────────────────────────────

  /// Creates a new homeowner account.
  @override
  Future<UserModel> registerCustomer({
    required String fullName,
    required String email,
    required String phoneNumber,
    String? password,
  }) async {
    await _delay();
    _assertEmailAvailable(email);
    if (password != null && password.length < 8) {
      throw const AuthException('Password must be at least 8 characters long.');
    }
    final user = UserModel(
      id: '${_nextId++}',
      fullName: fullName.trim(),
      email: email.trim(),
      phoneNumber: phoneNumber.trim(),
      role: AppRole.homeowner,
      status: 'active',
      createdAt: DateTime.now(),
    );
    _users.add(user);
    _userPasswords[user.email.toLowerCase()] = password ?? _mockPassword;
    return user;
  }

  /// Creates a new independent technician account (pending approval).
  @override
  Future<UserModel> registerTechnician({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String serviceArea,
    required String password,
  }) async {
    await _delay();
    _assertEmailAvailable(email);
    if (fullName.trim().isEmpty) {
      throw const AuthException('Full name is required.');
    }
    if (phoneNumber.trim().isEmpty) {
      throw const AuthException('Phone number is required.');
    }
    if (serviceArea.trim().isEmpty) {
      throw const AuthException('Service area is required.');
    }
    if (password.length < 8) {
      throw const AuthException('Password must be at least 8 characters long.');
    }
    final user = UserModel(
      id: '${_nextId++}',
      fullName: fullName.trim(),
      email: email.trim(),
      phoneNumber: phoneNumber.trim(),
      role: AppRole.independentProvider,
      status: 'pending_verification',
      serviceArea: serviceArea.trim(),
      createdAt: DateTime.now(),
    );
    _users.add(user);
    _userPasswords[user.email.toLowerCase()] = password;
    return user;
  }

  /// Creates a new company account (pending approval).
  @override
  Future<UserModel> registerCompany({
    required String ownerFullName,
    required String email,
    required String phoneNumber,
    required String companyName,
    required String serviceArea,
    String? password,
  }) async {
    await _delay();
    _assertEmailAvailable(email);
    final user = UserModel(
      id: '${_nextId++}',
      fullName: ownerFullName.trim(),
      email: email.trim(),
      phoneNumber: phoneNumber.trim(),
      role: AppRole.company,
      status: 'pending_verification',
      companyName: companyName.trim(),
      serviceArea: serviceArea.trim(),
      createdAt: DateTime.now(),
    );
    _users.add(user);
    _userPasswords[user.email.toLowerCase()] = password ?? _mockPassword;
    return user;
  }

  // ── Technician Activation ─────────────────────────────────────────────────

  /// Validates a company invite token.
  ///
  /// Returns `true` if the token is the known mock token.
  @override
  bool validateInviteToken(String token) => token == _mockInviteToken;

  /// Activates a company technician account using an invite token.
  ///
  /// Throws [AuthException] if the token is invalid.
  @override
  Future<UserModel> activateTechnicianAccount({
    required String token,
    required String fullName,
    required String password,
  }) async {
    await _delay();
    if (token != _mockInviteToken) {
      throw const AuthException('Invalid or expired invitation token.');
    }
    if (password.length < 8) {
      throw const AuthException('Password must be at least 8 characters long.');
    }
    final user = UserModel(
      id: '${_nextId++}',
      fullName: fullName.trim(),
      email: 'tech.activated@company.com',
      phoneNumber: '+85500000099',
      role: AppRole.companyTechnician,
      status: 'active',
      companyId: 'c1',
      companyName: 'Phnom Penh Fix Co.',
      createdAt: DateTime.now(),
    );
    _users.add(user);
    _userPasswords[user.email.toLowerCase()] = password;
    return user;
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  /// Simulates sending a password-reset email.
  @override
  Future<bool> requestPasswordReset(String email) async {
    await _delay();
    // In production this triggers a backend email send.
    // ignore: avoid_print
    print('[MockAuth] Password reset requested for $email');
    return true;
  }

  /// Simulates resetting a password with a token.
  @override
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
    final normalized = email.trim().toLowerCase();
    final exists = _users.any((u) => u.email.toLowerCase() == normalized);
    if (exists) {
      throw const AuthException(
          'An account with this email already exists.');
    }
  }
}
