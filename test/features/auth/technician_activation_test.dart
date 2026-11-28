import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
    late FakeFirebaseFirestore firestore;

    setUp(() async {
      fakeAuth = FakeFirebaseAuth();
      firestore = FakeFirebaseFirestore();
      authService = await createTestFirebaseAuthService(
        fakeAuth: fakeAuth,
        firestore: firestore,
      );
    });

    test('validates valid invite token', () {
      expect(authService.validateInviteToken(testTechnicianInviteId), isTrue);
      expect(authService.validateInviteToken(''), isFalse);
    });

    test('activateTechnicianAccount creates company technician with correct association', () async {
      await seedTechnicianInvite(firestore);
      final user = await authService.activateTechnicianAccount(
        token: testTechnicianInviteId,
        fullName: 'Borey Nhem',
        password: 'password123',
        email: testTechnicianEmail,
      );

      expect(user.fullName, equals('Borey Nhem'));
      expect(user.role, equals(AppRole.companyTechnician));
      expect(user.companyId, testTechnicianCompanyId);
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
              token: testTechnicianInviteId,
              email: testTechnicianEmail,
              companyName: 'Phnom Penh Fix Co.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activate Account'), findsNWidgets(2));
      expect(find.text('Phnom Penh Fix Co.'), findsOneWidget);
      expect(find.text(testTechnicianEmail), findsOneWidget);
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

    testWidgets('links without a recipient show the invalid state at 360dp',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(authService)],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            ),
            home: const TechnicianActivationScreen(token: testTechnicianInviteId),
          ),
        ),
      );

      expect(find.text('Invalid or Expired Link'), findsOneWidget);
      expect(find.text('Create Password'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
