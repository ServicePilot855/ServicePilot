import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_service.dart';
import 'package:service_pilot/core/auth/firebase_auth_service.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake implementation of [UserMetadata] for testing.
class FakeUserMetadata extends Fake implements UserMetadata {
  @override
  final DateTime creationTime;

  FakeUserMetadata({DateTime? creationTime})
      : creationTime = creationTime ?? DateTime(2026, 1, 1);
}

/// Fake implementation of [User] for testing.
class FakeUser extends Fake implements User {
  @override
  final String uid;

  @override
  String? email;

  @override
  String? displayName;

  @override
  String? phoneNumber;

  @override
  final UserMetadata metadata;

  FakeUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    DateTime? creationTime,
  }) : metadata = FakeUserMetadata(creationTime: creationTime);

  @override
  Future<void> updateDisplayName(String? name) async {
    displayName = name;
  }
}

/// Fake implementation of [UserCredential] for testing.
class FakeUserCredential extends Fake implements UserCredential {
  @override
  final User? user;

  FakeUserCredential({this.user});
}

/// Controllable fake [FirebaseAuth] for testing [FirebaseAuthService].
class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _currentUser;
  final Map<String, String> _users = {}; // email -> password
  final Map<String, FakeUser> _userProfiles = {}; // email -> FakeUser

  String? lastResetEmailSent;
  String? lastConfirmedResetCode;
  String? lastConfirmedNewPassword;

  // Error simulation hooks
  FirebaseAuthException? nextException;

  void seedUser({
    required String uid,
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
  }) {
    _users[email.toLowerCase()] = password;
    _userProfiles[email.toLowerCase()] = FakeUser(
      uid: uid,
      email: email,
      displayName: displayName,
      phoneNumber: phoneNumber,
    );
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (nextException != null) {
      final ex = nextException!;
      nextException = null;
      throw ex;
    }

    final normalized = email.toLowerCase();
    if (!_users.containsKey(normalized)) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found for that email.',
      );
    }
    if (_users[normalized] != password) {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'Wrong password provided.',
      );
    }

    final user = _userProfiles[normalized]!;
    _currentUser = user;
    return FakeUserCredential(user: user);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (nextException != null) {
      final ex = nextException!;
      nextException = null;
      throw ex;
    }

    final normalized = email.toLowerCase();
    if (_users.containsKey(normalized)) {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The account already exists for that email.',
      );
    }

    final user = FakeUser(
      uid: 'uid_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
    );
    _users[normalized] = password;
    _userProfiles[normalized] = user;
    _currentUser = user;
    return FakeUserCredential(user: user);
  }

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    if (nextException != null) {
      final ex = nextException!;
      nextException = null;
      throw ex;
    }

    final user = FakeUser(
      uid: 'google_uid_123',
      email: 'google.customer@example.com',
      displayName: 'Google Customer',
    );
    _currentUser = user;
    return FakeUserCredential(user: user);
  }

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async {
    return signInWithProvider(provider);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    if (nextException != null) {
      final ex = nextException!;
      nextException = null;
      throw ex;
    }
    lastResetEmailSent = email;
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    if (nextException != null) {
      final ex = nextException!;
      nextException = null;
      throw ex;
    }
    lastConfirmedResetCode = code;
    lastConfirmedNewPassword = newPassword;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseAuthService Unit Tests', () {
    late FakeFirebaseAuth fakeAuth;
    late FirebaseAuthService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      fakeAuth = FakeFirebaseAuth();
      authService = FirebaseAuthService(
        firebaseAuth: fakeAuth,
        prefs: prefs,
      );
    });

    // ── Login ───────────────────────────────────────────────────────────────

    test('login succeeds with valid credentials and returns UserModel', () async {
      fakeAuth.seedUser(
        uid: 'user-001',
        email: 'customer@test.com',
        password: 'password123',
        displayName: 'Dara Sok',
      );

      final user = await authService.login('customer@test.com', 'password123');

      expect(user.id, equals('user-001'));
      expect(user.email, equals('customer@test.com'));
      expect(user.fullName, equals('Dara Sok'));
      expect(user.role, equals(AppRole.homeowner));
      expect(user.status, equals('active'));
    });

    test('login maps user-not-found / invalid-credential to friendly error', () async {
      expect(
        () => authService.login('unknown@test.com', 'randompass'),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Invalid email or password.'),
        )),
      );
    });

    test('login maps wrong-password to friendly error', () async {
      fakeAuth.seedUser(
        uid: 'user-002',
        email: 'user@test.com',
        password: 'correctPassword',
      );

      expect(
        () => authService.login('user@test.com', 'wrongPassword'),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Invalid email or password.'),
        )),
      );
    });

    // ── Registration ────────────────────────────────────────────────────────

    test('registerCustomer creates Firebase user with homeowner role', () async {
      final user = await authService.registerCustomer(
        fullName: 'Bopha Keo',
        email: 'bopha@test.com',
        phoneNumber: '+85512345678',
        password: 'securePassword123',
      );

      expect(user.email, equals('bopha@test.com'));
      expect(user.fullName, equals('Bopha Keo'));
      expect(user.phoneNumber, equals('+85512345678'));
      expect(user.role, equals(AppRole.homeowner));
      expect(user.status, equals('active'));
      expect(fakeAuth.currentUser?.displayName, equals('Bopha Keo'));
    });

    test('registerCustomer throws AuthException on short password (< 8 chars)', () async {
      expect(
        () => authService.registerCustomer(
          fullName: 'Bopha Keo',
          email: 'bopha@test.com',
          phoneNumber: '+85512345678',
          password: 'short',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('at least 8 characters'),
        )),
      );
    });

    test('registerCustomer throws AuthException on email-already-in-use', () async {
      await authService.registerCustomer(
        fullName: 'First Customer',
        email: 'duplicate@test.com',
        phoneNumber: '+85512345678',
        password: 'password123',
      );

      expect(
        () => authService.registerCustomer(
          fullName: 'Second Customer',
          email: 'duplicate@test.com',
          phoneNumber: '+85598765432',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('already exists'),
        )),
      );
    });

    test('registerTechnician creates technician with pending_verification and serviceArea', () async {
      final user = await authService.registerTechnician(
        fullName: 'Vannak Heng',
        email: 'vannak@test.com',
        phoneNumber: '+85588990011',
        serviceArea: 'Chamkarmon, Phnom Penh',
        password: 'password123',
      );

      expect(user.fullName, equals('Vannak Heng'));
      expect(user.email, equals('vannak@test.com'));
      expect(user.role, equals(AppRole.independentProvider));
      expect(user.status, equals('pending_verification'));
      expect(user.serviceArea, equals('Chamkarmon, Phnom Penh'));
      expect(user.isPendingVerification, isTrue);
    });

    test('registerCompany creates company with pending_verification and companyName', () async {
      final user = await authService.registerCompany(
        ownerFullName: 'Sophea Lim',
        email: 'sophea@fixco.com',
        phoneNumber: '+85511223344',
        companyName: 'Phnom Penh Fix Co.',
        serviceArea: 'All Phnom Penh',
        password: 'password123',
      );

      expect(user.fullName, equals('Sophea Lim'));
      expect(user.email, equals('sophea@fixco.com'));
      expect(user.role, equals(AppRole.company));
      expect(user.status, equals('pending_verification'));
      expect(user.companyName, equals('Phnom Penh Fix Co.'));
    });

    // ── Password Reset ──────────────────────────────────────────────────────

    test('requestPasswordReset triggers sendPasswordResetEmail', () async {
      final success = await authService.requestPasswordReset('reset@test.com');

      expect(success, isTrue);
      expect(fakeAuth.lastResetEmailSent, equals('reset@test.com'));
    });

    test('resetPassword validates password length and confirms reset with token', () async {
      expect(
        () => authService.resetPassword(token: 'reset-token-123', newPassword: '123'),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('at least 8 characters'),
        )),
      );

      final success = await authService.resetPassword(
        token: 'reset-token-123',
        newPassword: 'newSecurePassword123',
      );

      expect(success, isTrue);
      expect(fakeAuth.lastConfirmedResetCode, equals('reset-token-123'));
      expect(fakeAuth.lastConfirmedNewPassword, equals('newSecurePassword123'));
    });

    // ── Technician Activation ───────────────────────────────────────────────

    test('validateInviteToken validates tokens', () {
      expect(authService.validateInviteToken('INVITE-2024-MOCK'), isTrue);
      expect(authService.validateInviteToken('INVITE-CUSTOM-123'), isTrue);
      expect(authService.validateInviteToken('INVALID-CODE'), isFalse);
    });

    test('activateTechnicianAccount creates active company technician', () async {
      final user = await authService.activateTechnicianAccount(
        token: 'INVITE-2024-MOCK',
        fullName: 'Borey Nhem',
        password: 'password123',
      );

      expect(user.fullName, equals('Borey Nhem'));
      expect(user.role, equals(AppRole.companyTechnician));
      expect(user.status, equals('active'));
      expect(user.companyName, equals('Phnom Penh Fix Co.'));
    });

    // ── Google Sign In ──────────────────────────────────────────────────────

    test('signInWithGoogle signs in customer and creates active user profile', () async {
      final user = await authService.signInWithGoogle();

      expect(user.id, equals('google_uid_123'));
      expect(user.email, equals('google.customer@example.com'));
      expect(user.fullName, equals('Google Customer'));
      expect(user.role, equals(AppRole.homeowner));
      expect(user.status, equals('active'));
    });

    // ── Session & Logout ────────────────────────────────────────────────────

    test('getCurrentUser retrieves cached profile after login or registration', () async {
      expect(await authService.getCurrentUser(), isNull);

      await authService.registerCustomer(
        fullName: 'Session User',
        email: 'session@test.com',
        phoneNumber: '+85512345678',
        password: 'password123',
      );

      final current = await authService.getCurrentUser();
      expect(current, isNotNull);
      expect(current?.fullName, equals('Session User'));
      expect(current?.email, equals('session@test.com'));
    });

    test('logout calls signOut and clears active session', () async {
      await authService.registerCustomer(
        fullName: 'Logout User',
        email: 'logout@test.com',
        phoneNumber: '+85512345678',
        password: 'password123',
      );

      expect(fakeAuth.currentUser, isNotNull);

      await authService.logout();

      expect(fakeAuth.currentUser, isNull);
      expect(await authService.getCurrentUser(), isNull);
    });

    // ── Auto-provision Demo Accounts ────────────────────────────────────────

    test('login auto-provisions demo customer when user-not-found occurs', () async {
      final user = await authService.login('customer@test.com', 'password123');

      expect(user.email, equals('customer@test.com'));
      expect(user.fullName, equals('Dara Sok'));
      expect(user.role, equals(AppRole.homeowner));
      expect(user.status, equals('active'));
    });

    test('login auto-provisions demo technician when user-not-found occurs', () async {
      final user = await authService.login('technician@test.com', 'password123');

      expect(user.email, equals('technician@test.com'));
      expect(user.fullName, equals('Virak Chan'));
      expect(user.role, equals(AppRole.independentProvider));
      expect(user.status, equals('pending_verification'));
      expect(user.serviceArea, equals('Toul Kork, Phnom Penh'));
    });

    test('login auto-provisions demo company when user-not-found occurs', () async {
      final user = await authService.login('company@test.com', 'password123');

      expect(user.email, equals('company@test.com'));
      expect(user.fullName, equals('Sophea Lim'));
      expect(user.role, equals(AppRole.company));
      expect(user.companyName, equals('Phnom Penh Fix Co.'));
    });

    test('login auto-provisions demo company tech and admin', () async {
      final techUser = await authService.login('tech@company.com', 'password123');
      expect(techUser.role, equals(AppRole.companyTechnician));

      final adminUser = await authService.login('admin@servicepilot.com', 'password123');
      expect(adminUser.role, equals(AppRole.admin));
    });

    // ── Validation Failures & Edge Cases ────────────────────────────────────

    test('registerTechnician validates empty fields', () {
      expect(
        () => authService.registerTechnician(
          fullName: '',
          email: 'tech@test.com',
          phoneNumber: '+85512345678',
          serviceArea: 'Toul Kork',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Full name is required'))),
      );

      expect(
        () => authService.registerTechnician(
          fullName: 'Valid Name',
          email: 'tech@test.com',
          phoneNumber: '',
          serviceArea: 'Toul Kork',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Phone number is required'))),
      );

      expect(
        () => authService.registerTechnician(
          fullName: 'Valid Name',
          email: 'tech@test.com',
          phoneNumber: '+85512345678',
          serviceArea: '',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Service area is required'))),
      );

      expect(
        () => authService.registerTechnician(
          fullName: 'Valid Name',
          email: 'tech@test.com',
          phoneNumber: '+85512345678',
          serviceArea: 'Toul Kork',
          password: 'short',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('at least 8 characters'))),
      );
    });

    test('registerCompany validates empty fields and password length', () {
      expect(
        () => authService.registerCompany(
          ownerFullName: '',
          email: 'c@test.com',
          phoneNumber: '+855112233',
          companyName: 'Company',
          serviceArea: 'PP',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Owner full name is required'))),
      );

      expect(
        () => authService.registerCompany(
          ownerFullName: 'Owner',
          email: 'c@test.com',
          phoneNumber: '',
          companyName: 'Company',
          serviceArea: 'PP',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Phone number is required'))),
      );

      expect(
        () => authService.registerCompany(
          ownerFullName: 'Owner',
          email: 'c@test.com',
          phoneNumber: '+855112233',
          companyName: '',
          serviceArea: 'PP',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Company name is required'))),
      );

      expect(
        () => authService.registerCompany(
          ownerFullName: 'Owner',
          email: 'c@test.com',
          phoneNumber: '+855112233',
          companyName: 'Company',
          serviceArea: '',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Service area is required'))),
      );

      expect(
        () => authService.registerCompany(
          ownerFullName: 'Owner',
          email: 'c@test.com',
          phoneNumber: '+855112233',
          companyName: 'Company',
          serviceArea: 'PP',
          password: 'short',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('at least 8 characters'))),
      );
    });

    test('requestPasswordReset validates empty email', () {
      expect(
        () => authService.requestPasswordReset(''),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Email is required'))),
      );
    });

    test('resetPassword validates token and password', () {
      expect(
        () => authService.resetPassword(token: '', newPassword: 'password123'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('missing or invalid'))),
      );
    });

    test('activateTechnicianAccount validates invalid token and short password', () {
      expect(
        () => authService.activateTechnicianAccount(
          token: 'INVALID',
          fullName: 'Borey',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Invalid or expired'))),
      );

      expect(
        () => authService.activateTechnicianAccount(
          token: 'INVITE-2024-MOCK',
          fullName: 'Borey',
          password: 'short',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('at least 8 characters'))),
      );
    });

    // ── Error Code Mappings ─────────────────────────────────────────────────

    // ── Resilient Development & Mock Fallback Mode ─────────────────────────

    group('Resilient Development & Fallback Mode', () {
      test('registerCustomer seamlessly creates user locally when Firebase is unconfigured', () async {
        fakeAuth.nextException = FirebaseAuthException(
          code: 'configuration-not-found',
          message: 'CONFIGURATION_NOT_FOUND',
        );

        final user = await authService.registerCustomer(
          fullName: 'Saoly Thang',
          email: 'saoly.thang@gmail.com',
          phoneNumber: '067778763',
          password: 'password123',
        );

        expect(user.fullName, equals('Saoly Thang'));
        expect(user.email, equals('saoly.thang@gmail.com'));
        expect(user.phoneNumber, equals('067778763'));
        expect(user.role, equals(AppRole.homeowner));
        expect(user.status, equals('active'));

        // Can immediately log in with new credentials in dev mode
        fakeAuth.nextException = FirebaseAuthException(
          code: 'configuration-not-found',
          message: 'CONFIGURATION_NOT_FOUND',
        );
        final loggedInUser = await authService.login('saoly.thang@gmail.com', 'password123');
        expect(loggedInUser.fullName, equals('Saoly Thang'));

        // Fails with wrong password
        fakeAuth.nextException = FirebaseAuthException(
          code: 'configuration-not-found',
          message: 'CONFIGURATION_NOT_FOUND',
        );
        expect(
          () => authService.login('saoly.thang@gmail.com', 'wrongpassword'),
          throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Invalid email or password'))),
        );
      });

      test('all demo personas log in cleanly when Firebase Auth is unconfigured', () async {
        final personas = [
          ('customer@test.com', 'Dara Sok', AppRole.homeowner),
          ('technician@test.com', 'Virak Chan', AppRole.independentProvider),
          ('company@test.com', 'Sophea Lim', AppRole.company),
          ('tech@company.com', 'Borey Nhem', AppRole.companyTechnician),
          ('admin@servicepilot.com', 'Admin User', AppRole.admin),
        ];

        for (final persona in personas) {
          fakeAuth.nextException = FirebaseAuthException(
            code: 'configuration-not-found',
            message: 'CONFIGURATION_NOT_FOUND',
          );
          final user = await authService.login(persona.$1, 'password123');
          expect(user.email, equals(persona.$1));
          expect(user.fullName, equals(persona.$2));
          expect(user.role, equals(persona.$3));
        }
      });

      test('session persists across app reloads via SharedPreferences', () async {
        fakeAuth.nextException = FirebaseAuthException(
          code: 'configuration-not-found',
          message: 'CONFIGURATION_NOT_FOUND',
        );

        final user = await authService.registerCustomer(
          fullName: 'Persisted User',
          email: 'persisted@example.com',
          phoneNumber: '+85511223344',
          password: 'password123',
        );

        // Simulate app restart: create a new service with same SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final newService = FirebaseAuthService(
          firebaseAuth: FakeFirebaseAuth(), // no user in memory
          prefs: prefs,
        );

        final restored = await newService.getCurrentUser();
        expect(restored, isNotNull);
        expect(restored?.id, equals(user.id));
        expect(restored?.email, equals('persisted@example.com'));
      });
    });
  });
}
