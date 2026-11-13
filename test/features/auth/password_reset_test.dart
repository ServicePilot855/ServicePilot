import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/firebase_auth_service.dart';
import 'package:service_pilot/features/auth/screens/forgot_password_screen.dart';
import 'package:service_pilot/features/auth/screens/reset_password_screen.dart';

import '../../helpers/test_firebase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SCRUM-52 / US-07: Password Reset Tests', () {
    late FakeFirebaseAuth fakeAuth;
    late FirebaseAuthService authService;

    setUp(() async {
      fakeAuth = FakeFirebaseAuth();
      authService = await createTestFirebaseAuthService(fakeAuth: fakeAuth);
    });

    test('requestPasswordReset sends reset email via Firebase Auth', () async {
      final result = await authService.requestPasswordReset('customer@example.com');
      expect(result, isTrue);
      expect(fakeAuth.lastResetEmailSent, equals('customer@example.com'));
    });

    test('resetPassword confirms password reset with token via Firebase Auth', () async {
      final result = await authService.resetPassword(
        token: 'RESET-TOKEN-XYZ',
        newPassword: 'newSecurePassword123',
      );
      expect(result, isTrue);
      expect(fakeAuth.lastConfirmedResetCode, equals('RESET-TOKEN-XYZ'));
      expect(fakeAuth.lastConfirmedNewPassword, equals('newSecurePassword123'));
    });

    testWidgets('forgot password screen renders and accepts email', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('reset password screen renders new password inputs and strength bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(
            home: ResetPasswordScreen(token: 'RESET-TOKEN-123'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set new password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Reset Password'), findsWidgets);
    });
  });
}
