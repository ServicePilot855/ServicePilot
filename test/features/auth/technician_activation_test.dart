import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/firebase_auth_service.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/screens/technician_activation_screen.dart';

import '../../helpers/test_firebase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SCRUM-49 / US-04: Company Technician Account Activation Tests', () {
    late FakeFirebaseAuth fakeAuth;
    late FirebaseAuthService authService;

    setUp(() async {
      fakeAuth = FakeFirebaseAuth();
      authService = await createTestFirebaseAuthService(fakeAuth: fakeAuth);
    });

    test('validates valid invite token', () {
      expect(authService.validateInviteToken('INVITE-ABC-123'), isTrue);
      expect(authService.validateInviteToken(''), isFalse);
    });

    test('activateTechnicianAccount creates company technician with correct association', () async {
      final user = await authService.activateTechnicianAccount(
        token: 'INVITE-ABC-123',
        fullName: 'Borey Nhem',
        password: 'password123',
      );

      expect(user.fullName, equals('Borey Nhem'));
      expect(user.role, equals(AppRole.companyTechnician));
      expect(user.companyName, isNotNull);
      expect(user.status, equals('active'));
    });

    testWidgets('renders activation form when token is valid', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(
            home: TechnicianActivationScreen(
              token: 'INVITE-ABC-123',
              companyName: 'Phnom Penh Fix Co.',
            ),
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
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(
            home: TechnicianActivationScreen(token: ''),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid or Expired Link'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });
  });
}
