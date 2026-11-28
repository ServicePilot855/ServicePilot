import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_service.dart';
import 'package:service_pilot/core/auth/firebase_auth_service.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_firebase_helper.dart';

class _UnavailableFirestore extends FakeFirebaseFirestore {
  @override
  Future<void> maybeThrowSecurityException(String path, Object method) async {
    throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseAuthService Production Unit Tests', () {
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
        email: 'customer@servicepilot.app',
        password: 'password123',
        displayName: 'Dara Sok',
      );

      final user = await authService.login('customer@servicepilot.app', 'password123');

      expect(user.id, equals('user-001'));
      expect(user.email, equals('customer@servicepilot.app'));
      expect(user.fullName, equals('Dara Sok'));
      expect(user.role, equals(AppRole.homeowner));
      expect(user.status, equals('active'));
    });

    test('login maps user-not-found to friendly error', () async {
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

    test('login validates empty email or password', () {
      expect(
        () => authService.login('', 'password'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Email is required'))),
      );

      expect(
        () => authService.login('test@test.com', ''),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Password is required'))),
      );
    });

    // ── Customer Registration ───────────────────────────────────────────────

    test('registerCustomer creates user with active status and homeowner role', () async {
      final user = await authService.registerCustomer(
        fullName: 'Dara Sok',
        email: 'dara@servicepilot.app',
        phoneNumber: '+85512345678',
        password: 'password123',
      );

      expect(user.fullName, equals('Dara Sok'));
      expect(user.email, equals('dara@servicepilot.app'));
      expect(user.phoneNumber, equals('+85512345678'));
      expect(user.role, equals(AppRole.homeowner));
      expect(user.status, equals('active'));
    });

    test('registerCustomer rejects duplicate email with friendly message', () async {
      fakeAuth.seedUser(
        uid: 'existing-1',
        email: 'existing@test.com',
        password: 'password123',
      );

      expect(
        () => authService.registerCustomer(
          fullName: 'Duplicate User',
          email: 'existing@test.com',
          phoneNumber: '+85512345678',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('already exists'),
        )),
      );
    });

    test('registerCustomer validates empty fields and short password', () {
      expect(
        () => authService.registerCustomer(
          fullName: '',
          email: 'test@test.com',
          phoneNumber: '+85512345678',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Full name is required'))),
      );

      expect(
        () => authService.registerCustomer(
          fullName: 'Name',
          email: '',
          phoneNumber: '+85512345678',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Email is required'))),
      );

      expect(
        () => authService.registerCustomer(
          fullName: 'Name',
          email: 'test@test.com',
          phoneNumber: '',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Phone number is required'))),
      );

      expect(
        () => authService.registerCustomer(
          fullName: 'Name',
          email: 'test@test.com',
          phoneNumber: '+85512345678',
          password: 'short',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('at least 8 characters'))),
      );
    });

    // ── Technician Registration ─────────────────────────────────────────────

    test('registerTechnician creates user with pending_verification and independentProvider role', () async {
      final user = await authService.registerTechnician(
        fullName: 'Virak Chan',
        email: 'virak@test.com',
        phoneNumber: '+85587654321',
        serviceArea: 'Toul Kork, Phnom Penh',
        password: 'password123',
      );

      expect(user.fullName, equals('Virak Chan'));
      expect(user.email, equals('virak@test.com'));
      expect(user.role, equals(AppRole.independentProvider));
      expect(user.status, equals('pending_verification'));
      expect(user.serviceArea, equals('Toul Kork, Phnom Penh'));
    });

    test('registerTechnician validates empty fields and password length', () {
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

    // ── Company Registration ────────────────────────────────────────────────

    test('registerCompany creates user with pending_verification and company role', () async {
      final user = await authService.registerCompany(
        ownerFullName: 'Sophea Lim',
        email: 'sophea@fixco.com',
        phoneNumber: '+85511223344',
        companyName: 'Phnom Penh Fix Co.',
        serviceArea: 'Phnom Penh',
        password: 'password123',
      );

      expect(user.fullName, equals('Sophea Lim'));
      expect(user.email, equals('sophea@fixco.com'));
      expect(user.role, equals(AppRole.company));
      expect(user.status, equals('pending_verification'));
      expect(user.companyName, equals('Phnom Penh Fix Co.'));
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
          email: '',
          phoneNumber: '+855112233',
          companyName: 'Company',
          serviceArea: 'PP',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Email is required'))),
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

    // ── Technician Activation ───────────────────────────────────────────────

    test('sign-in loads verified technician membership on a fresh device', () async {
      final firestore = FakeFirebaseFirestore();
      const email = 'borey@example.test';
      fakeAuth.seedUser(uid: 'tech-1', email: email, password: 'password123');
      await firestore.collection('users').doc('tech-1').set({
        'id': 'tech-1',
        'fullName': 'Borey Nhem',
        'email': email,
        'phoneNumber': '',
        'role': 'company_technician',
        'status': 'active',
        'companyId': 'company-1',
      });
      final freshDevice = FirebaseAuthService(
        firebaseAuth: fakeAuth,
        prefs: await SharedPreferences.getInstance(),
        firestore: firestore,
      );

      final user = await freshDevice.login(email, 'password123');
      expect(user.role, AppRole.companyTechnician);
      expect(user.companyId, 'company-1');
    });

    test('activation rejects an invitation missing from Firestore', () async {
      final service = FirebaseAuthService(
        firebaseAuth: fakeAuth,
        prefs: await SharedPreferences.getInstance(),
        firestore: FakeFirebaseFirestore(),
      );
      await expectLater(
        service.activateTechnicianAccount(
          token: testTechnicianInviteId,
          fullName: 'Borey Nhem',
          password: 'password123',
          email: testTechnicianEmail,
        ),
        throwsA(isA<AuthException>()),
      );
      expect(fakeAuth.currentUser, isNull);
      await expectLater(
        fakeAuth.signInWithEmailAndPassword(
          email: testTechnicianEmail,
          password: 'password123',
        ),
        throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'user-not-found')),
      );
    });

    test('fresh sign-in refuses to infer a role when Firestore is unavailable', () async {
      fakeAuth.seedUser(
        uid: 'tech-1',
        email: testTechnicianEmail,
        password: 'password123',
      );
      final service = FirebaseAuthService(
        firebaseAuth: fakeAuth,
        prefs: await SharedPreferences.getInstance(),
        firestore: _UnavailableFirestore(),
      );

      await expectLater(
        service.login(testTechnicianEmail, 'password123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('server membership replaces a stale homeowner cache', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirebaseAuthService(
        firebaseAuth: fakeAuth,
        prefs: await SharedPreferences.getInstance(),
        firestore: firestore,
      );
      fakeAuth.seedUser(
        uid: 'legacy-tech',
        email: testTechnicianEmail,
        password: 'password123',
      );
      final before = await service.login(testTechnicianEmail, 'password123');
      expect(before.role, AppRole.homeowner);
      await firestore.collection('users').doc(before.id).set({
        'role': 'companyTechnician',
        'status': 'active',
        'companyId': testTechnicianCompanyId,
      });

      final restored = await service.getCurrentUser();
      expect(restored?.role, AppRole.companyTechnician);
      expect(restored?.companyId, testTechnicianCompanyId);
    });

    test('validateInviteToken validates token format', () {
      expect(authService.validateInviteToken(testTechnicianInviteId), isTrue);
      expect(authService.validateInviteToken('tok12345'), isFalse);
      expect(authService.validateInviteToken(''), isFalse);
    });

    test('activation persists membership and rejects replay', () async {
      final firestore = FakeFirebaseFirestore();
      await seedTechnicianInvite(firestore);
      final service = FirebaseAuthService(
        firebaseAuth: fakeAuth,
        prefs: await SharedPreferences.getInstance(),
        firestore: firestore,
      );
      Future<UserModel> activate() => service.activateTechnicianAccount(
        token: testTechnicianInviteId,
        fullName: 'Borey Nhem',
        password: 'password123',
        email: testTechnicianEmail,
      );

      final user = await activate();
      expect(user.fullName, equals('Borey Nhem'));
      expect(user.role, equals(AppRole.companyTechnician));
      expect(user.status, equals('active'));
      expect(user.companyId, testTechnicianCompanyId);
      expect(fakeAuth.currentUser, isNull);
      final account = await firestore.collection('users').doc(user.id).get();
      expect(account.data()?['companyId'], testTechnicianCompanyId);
      final entry = await firestore.collection('providers')
          .doc(testTechnicianCompanyId).collection('technicians').doc(user.id).get();
      expect(entry.data(), {'id': user.id, 'fullName': 'Borey Nhem'});
      await expectLater(activate(), throwsA(isA<AuthException>()));
      expect(fakeAuth.currentUser, isNull);

      final signedIn = await service.login(testTechnicianEmail, 'password123');
      expect(signedIn.role, AppRole.companyTechnician);
      expect(signedIn.companyId, testTechnicianCompanyId);
    });

    test('activation rejects expired and wrong-recipient invitations', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirebaseAuthService(
        firebaseAuth: fakeAuth,
        prefs: await SharedPreferences.getInstance(),
        firestore: firestore,
      );
      Future<UserModel> activate(String email) => service.activateTechnicianAccount(
        token: testTechnicianInviteId,
        fullName: 'Borey Nhem',
        password: 'password123',
        email: email,
      );
      await seedTechnicianInvite(firestore, expiresAt: DateTime(2020));
      await expectLater(activate(testTechnicianEmail), throwsA(isA<AuthException>()));
      await seedTechnicianInvite(firestore);
      await expectLater(activate('uninvited@example.test'), throwsA(isA<AuthException>()));
      expect((await firestore.collection('users').get()).docs, isEmpty);
      final invitation = await firestore.collection('technicianInvites')
          .doc(testTechnicianInviteId).get();
      expect(invitation.data(), isNot(contains('redeemedBy')));
    });

    test('activateTechnicianAccount validates invalid token and short password', () {
      expect(
        () => authService.activateTechnicianAccount(
          token: '',
          fullName: 'Borey',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Invalid or expired'))),
      );

      expect(
        () => authService.activateTechnicianAccount(
          token: testTechnicianInviteId,
          fullName: 'Borey',
          password: 'short',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('at least 8 characters'))),
      );
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
    });

    test('login links an unlinked independent technician provider profile',
        () async {
      final firestore = FakeFirebaseFirestore();
      final prefs = await SharedPreferences.getInstance();
      final serviceWithFirestore = FirebaseAuthService(
        firebaseAuth: fakeAuth,
        prefs: prefs,
        firestore: firestore,
      );

      fakeAuth.seedUser(
        uid: 'tech-legacy-1',
        email: 'technician@test.com',
        password: 'password123',
        displayName: 'Virak Chan',
      );

      final user = await serviceWithFirestore.login(
        'technician@test.com',
        'password123',
      );

      expect(user.role, equals(AppRole.independentProvider));
      final providerDoc =
          await firestore.collection('providers').doc('tech-legacy-1').get();
      expect(providerDoc.exists, isTrue);
      expect(providerDoc.data()?['providerType'], equals('independent'));
      expect(providerDoc.data()?['name'], equals('Virak Chan'));
      expect(providerDoc.data()?['status'], equals('pending_verification'));
    });
  });
}
