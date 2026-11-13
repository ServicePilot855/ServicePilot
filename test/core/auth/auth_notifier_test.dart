import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/auth/firebase_auth_service.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_auth_service_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthNotifier with FirebaseAuthService Tests', () {
    late FakeFirebaseAuth fakeAuth;
    late FirebaseAuthService authService;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      fakeAuth = FakeFirebaseAuth();
      authService = FirebaseAuthService(
        firebaseAuth: fakeAuth,
        prefs: prefs,
      );

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is AuthStateUnauthenticated', () {
      final state = container.read(authProvider);
      expect(state, isA<AuthStateUnauthenticated>());
      expect(container.read(authProvider.notifier).currentUser, isNull);
      expect(container.read(authProvider.notifier).isAuthenticated, isFalse);
    });

    test('login sets AuthStateAuthenticated on success', () async {
      fakeAuth.seedUser(
        uid: 'user-001',
        email: 'customer@test.com',
        password: 'password123',
        displayName: 'Dara Sok',
      );

      final notifier = container.read(authProvider.notifier);
      await notifier.login('customer@test.com', 'password123');

      final state = container.read(authProvider);
      expect(state, isA<AuthStateAuthenticated>());
      final authUser = (state as AuthStateAuthenticated).user;
      expect(authUser.email, equals('customer@test.com'));
      expect(authUser.fullName, equals('Dara Sok'));
      expect(authUser.role, equals(AppRole.homeowner));
      expect(notifier.isAuthenticated, isTrue);
      expect(notifier.currentUser, equals(authUser));
    });

    test('login sets AuthStateError on failure and clearError clears it', () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.login('invalid@test.com', 'badpass');

      final errorState = container.read(authProvider);
      expect(errorState, isA<AuthStateError>());
      expect((errorState as AuthStateError).message, contains('Invalid email or password'));

      notifier.clearError();
      final clearedState = container.read(authProvider);
      expect(clearedState, isA<AuthStateUnauthenticated>());
    });

    test('checkAuthStatus restores session into AuthStateAuthenticated', () async {
      final notifier = container.read(authProvider.notifier);

      // Register first to persist session in SharedPreferences
      await notifier.registerCustomer(
        fullName: 'Active User',
        email: 'active@test.com',
        phoneNumber: '+85512345678',
        password: 'password123',
      );

      // Now create a fresh ProviderContainer simulating app restart
      final newContainer = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
        ],
      );

      expect(newContainer.read(authProvider), isA<AuthStateUnauthenticated>());

      // Restore session
      await newContainer.read(authProvider.notifier).checkAuthStatus();

      final restoredState = newContainer.read(authProvider);
      expect(restoredState, isA<AuthStateAuthenticated>());
      expect((restoredState as AuthStateAuthenticated).user.email, equals('active@test.com'));

      newContainer.dispose();
    });

    test('registerCustomer returns true on success and leaves state unauthenticated for login', () async {
      final notifier = container.read(authProvider.notifier);
      final success = await notifier.registerCustomer(
        fullName: 'New Customer',
        email: 'newcustomer@test.com',
        phoneNumber: '+85512345678',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
    });

    test('registerTechnician returns true on valid registration', () async {
      final notifier = container.read(authProvider.notifier);
      final success = await notifier.registerTechnician(
        fullName: 'New Tech',
        email: 'newtech@test.com',
        phoneNumber: '+85588990011',
        serviceArea: 'Toul Kork',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
    });

    test('registerCompany returns true on valid registration', () async {
      final notifier = container.read(authProvider.notifier);
      final success = await notifier.registerCompany(
        ownerFullName: 'Company Owner',
        email: 'owner@company.com',
        phoneNumber: '+85511223344',
        companyName: 'Best Services',
        serviceArea: 'Phnom Penh',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
    });

    test('signInWithGoogle signs in and sets AuthStateAuthenticated', () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithGoogle();

      final state = container.read(authProvider);
      expect(state, isA<AuthStateAuthenticated>());
      expect((state as AuthStateAuthenticated).user.role, equals(AppRole.homeowner));
    });

    test('activateTechnicianAccount activates user with valid invite token', () async {
      final notifier = container.read(authProvider.notifier);
      final success = await notifier.activateTechnicianAccount(
        token: 'INVITE-2024-MOCK',
        fullName: 'Activated Tech',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
    });

    test('requestPasswordReset returns true on success', () async {
      final notifier = container.read(authProvider.notifier);
      final success = await notifier.requestPasswordReset('customer@test.com');
      expect(success, isTrue);
    });

    test('resetPassword returns true on valid reset', () async {
      final notifier = container.read(authProvider.notifier);
      final success = await notifier.resetPassword(
        token: 'token-123',
        newPassword: 'newPassword123',
      );
      expect(success, isTrue);
    });

    test('logout transitions to AuthStateUnauthenticated', () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithGoogle();

      expect(container.read(authProvider), isA<AuthStateAuthenticated>());

      await notifier.logout();

      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
      expect(notifier.currentUser, isNull);
    });
  });
}
