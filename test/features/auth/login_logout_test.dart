import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_service.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/mock/mock_auth_service.dart';
import 'package:service_pilot/features/auth/screens/login_screen.dart';

void main() {
  group('SCRUM-50, SCRUM-51, SCRUM-53: Login, Logout, Admin Access Tests', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
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

    testWidgets('renders login screen with inputs, buttons, and demo hints', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
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
        const ProviderScope(
          child: MaterialApp(
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
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.login('customer@test.com', 'password123');
      expect(container.read(authProvider), isA<AuthStateAuthenticated>());

      await notifier.logout();
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());
    });
  });
}
