import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/mock/mock_auth_service.dart';
import 'package:service_pilot/features/auth/screens/technician_activation_screen.dart';

void main() {
  group('SCRUM-49 / US-04: Company Technician Account Activation Tests', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
    });

    test('validates valid invite token', () {
      expect(authService.validateInviteToken('INVITE-2024-MOCK'), isTrue);
      expect(authService.validateInviteToken('EXPIRED_OR_INVALID'), isFalse);
    });

    test('activateTechnicianAccount creates company technician with correct association', () async {
      final user = await authService.activateTechnicianAccount(
        token: 'INVITE-2024-MOCK',
        fullName: 'Borey Nhem',
        password: 'password123',
      );

      expect(user.fullName, equals('Borey Nhem'));
      expect(user.role, equals(AppRole.companyTechnician));
      expect(user.companyName, equals('Phnom Penh Fix Co.'));
      expect(user.status, equals('active'));
    });

    testWidgets('renders activation form when token is valid', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TechnicianActivationScreen(token: 'INVITE-2024-MOCK'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activate Account'), findsNWidgets(2));
      expect(find.text('Phnom Penh Fix Co.'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Create Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('shows invalid link message when token is invalid', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TechnicianActivationScreen(token: 'INVALID_TOKEN'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid or Expired Link'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });
  });
}
