import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/firebase_auth_service.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/screens/register_company_screen.dart';

import '../../helpers/test_firebase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SCRUM-48 / US-03: Company Registration Unit & Widget Tests', () {
    late FakeFirebaseAuth fakeAuth;
    late FirebaseAuthService authService;

    setUp(() async {
      fakeAuth = FakeFirebaseAuth();
      authService = await createTestFirebaseAuthService(fakeAuth: fakeAuth);
    });

    test('registerCompany creates company account with pending_verification status', () async {
      final user = await authService.registerCompany(
        ownerFullName: 'Sophea Lim',
        email: 'sophea.newcompany@test.com',
        phoneNumber: '+85511223344',
        companyName: 'CoolAir Service Co.',
        serviceArea: 'Toul Kork, Sen Sok',
        password: 'password123',
      );

      expect(user.fullName, equals('Sophea Lim'));
      expect(user.email, equals('sophea.newcompany@test.com'));
      expect(user.companyName, equals('CoolAir Service Co.'));
      expect(user.role, equals(AppRole.company));
      expect(user.status, equals('pending_verification'));
      expect(user.isPendingVerification, isTrue);
    });

    Future<void> pumpCompanyScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const MaterialApp(
            home: RegisterCompanyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('details page shows all company fields', (tester) async {
      await pumpCompanyScreen(tester);

      expect(find.text('Company Registration'), findsOneWidget);
      expect(find.text('Manage your team'), findsOneWidget);
      expect(find.text('Owner / Admin Full Name'), findsOneWidget);
      expect(find.text('Company Name'), findsOneWidget);
      expect(find.text('Company Email Address'), findsOneWidget);
      expect(find.text('Contact Phone Number'), findsOneWidget);
      expect(find.text('Office Address & Service Area'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Password'), findsNothing);
    });

    testWidgets('shows validation errors when continuing with empty details', (tester) async {
      await pumpCompanyScreen(tester);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Owner full name is required'), findsOneWidget);
      expect(find.text('Company name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Address and service area are required'), findsOneWidget);
    });

    testWidgets('valid details lead to the password page', (tester) async {
      await pumpCompanyScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Sophea Lim');
      await tester.enterText(fields.at(1), 'CoolAir Service Co.');
      await tester.enterText(fields.at(2), 'owner@coolair.example');
      await tester.enterText(fields.at(3), '+85511223344');
      await tester.enterText(fields.at(4), 'St. 315, Toul Kork');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Set up your password'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Register Company'), findsOneWidget);
      expect(find.textContaining('business'), findsOneWidget);

      await tester.tap(find.text('Register Company'));
      await tester.pumpAndSettle();
      expect(find.text('Password is required'), findsOneWidget);
    });
  });
}
