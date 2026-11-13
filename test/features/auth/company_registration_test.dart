import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/mock/mock_auth_service.dart';
import 'package:service_pilot/features/auth/screens/register_company_screen.dart';

void main() {
  group('SCRUM-48 / US-03: Company Registration Unit & Widget Tests', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
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

    testWidgets('renders all required company registration fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterCompanyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Company Registration'), findsOneWidget);
      expect(find.text('Manage your team'), findsOneWidget);
      expect(find.text('Owner / Admin Full Name'), findsOneWidget);
      expect(find.text('Company Name'), findsOneWidget);
      expect(find.text('Company Email Address'), findsOneWidget);
      expect(find.text('Contact Phone Number'), findsOneWidget);
      expect(find.text('Office Address & Service Area'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Register Company'), findsOneWidget);
    });

    testWidgets('shows validation errors when company form is submitted empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterCompanyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final registerBtn = find.text('Register Company');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Owner full name is required'), findsOneWidget);
      expect(find.text('Company name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Address and service area are required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });
}
