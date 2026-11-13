import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_service.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/auth/firebase_auth_service.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/screens/login_screen.dart';

import '../../helpers/test_firebase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SCRUM-50, SCRUM-51, SCRUM-53: Login, Logout, Admin Access Tests', () {
    late FakeFirebaseAuth fakeAuth;
    late FirebaseAuthService authService;

    setUp(() async {
      fakeAuth = FakeFirebaseAuth();
      fakeAuth.seedUser(
        uid: 'cust-1',
        email: 'customer@test.com',
        password: 'password123',
        displayName: 'Customer User',
      );
      fakeAuth.seedUser(
        uid: 'adm-1',
        email: 'admin@servicepilot.com',
        password: 'password123',
        displayName: 'Admin User',
      );
      authService = await createTestFirebaseAuthService(fakeAuth: fakeAuth);
    });

    test('login succeeds with valid customer credentials', () async {
      final user = await authService.login('customer@test.com', 'password123');
      expect(user.email, equals('customer@test.com'));
      expect(user.role, equals(AppRole.homeowner));
      expect(user.status, equals('active'));
    });

    test('login succeeds with Platform Admin credentials', () async {
      final user = await authService.login('admin@servicepilot.com', 'password123');
      expect(user.email, equals('admin@servicepilot.com'));
      expect(user.role, equals(AppRole.admin));
      expect(user.isAdmin, isTrue);
    });

    test('login fails with invalid credentials', () async {
      expect(
        () => authService.login('customer@test.com', 'wrongpassword'),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Invalid email or password'),
        )),
      );
    });

    testWidgets('renders login screen with inputs and buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Phone number or email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Log In'), findsWidgets);
      expect(find.text('Continue with Google (Customer)'), findsOneWidget);
    });

    testWidgets('shows validation errors when login submitted with empty fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final loginBtn = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your phone number or email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    test('AuthNotifier logout clears authenticated user state', () async {
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
        ],
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.login('customer@test.com', 'password123');
      expect(container.read(authProvider), isA<AuthStateAuthenticated>());

      await notifier.logout();
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
    });
  });
}
