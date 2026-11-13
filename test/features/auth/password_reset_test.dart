import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/auth/mock/mock_auth_service.dart';
import 'package:service_pilot/features/auth/screens/forgot_password_screen.dart';
import 'package:service_pilot/features/auth/screens/reset_password_screen.dart';

void main() {
  group('SCRUM-52 / US-07: Password Reset Tests', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
    });

    test('requestPasswordReset simulates sending reset link', () async {
      final result = await authService.requestPasswordReset('customer@test.com');
      expect(result, isTrue);
    });

    test('resetPassword updates user password with token', () async {
      final result = await authService.resetPassword(
        token: 'RESET-MOCK-TOKEN',
        newPassword: 'newSecurePassword123',
      );
      expect(result, isTrue);
    });

    testWidgets('forgot password screen renders and accepts email', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
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
        const ProviderScope(
          child: MaterialApp(
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
