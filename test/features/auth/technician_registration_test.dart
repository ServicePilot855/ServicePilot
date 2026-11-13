import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_service.dart';
import 'package:service_pilot/core/auth/firebase_auth_service.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/auth/screens/register_technician_screen.dart';

import '../../helpers/test_firebase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SCRUM-64 & SCRUM-65: Technician Model & Auth Service Unit Tests', () {
    late FakeFirebaseAuth fakeAuth;
    late FirebaseAuthService authService;

    setUp(() async {
      fakeAuth = FakeFirebaseAuth();
      authService = await createTestFirebaseAuthService(fakeAuth: fakeAuth);
    });

    test('UserModel supports technician fields and JSON serialization', () {
      final now = DateTime.now();
      final user = UserModel(
        id: 'tech-101',
        fullName: 'Chhunhour Tiek',
        email: 'chhunhour@test.com',
        phoneNumber: '+85512345678',
        role: AppRole.independentProvider,
        status: 'pending_verification',
        serviceArea: 'Sen Sok, Phnom Penh',
        createdAt: now,
      );

      expect(user.isPendingVerification, isTrue);
      expect(user.isIndependentTechnician, isTrue);
      expect(user.isActive, isFalse);
      expect(user.serviceArea, equals('Sen Sok, Phnom Penh'));

      // Test JSON roundtrip
      final json = user.toJson();
      expect(json['role'], equals('independent_provider'));
      expect(json['status'], equals('pending_verification'));
      expect(json['serviceArea'], equals('Sen Sok, Phnom Penh'));

      final fromJson = UserModel.fromJson(json);
      expect(fromJson.id, equals(user.id));
      expect(fromJson.email, equals(user.email));
      expect(fromJson.serviceArea, equals(user.serviceArea));
      expect(fromJson.role, equals(AppRole.independentProvider));
    });

    test('registerTechnician creates technician with pending_verification status', () async {
      final user = await authService.registerTechnician(
        fullName: 'Vannak Heng',
        email: 'vannak.unique@test.com',
        phoneNumber: '+85588990011',
        serviceArea: 'Chamkarmon, Phnom Penh',
        password: 'securePassword123',
      );

      expect(user.fullName, equals('Vannak Heng'));
      expect(user.email, equals('vannak.unique@test.com'));
      expect(user.role, equals(AppRole.independentProvider));
      expect(user.status, equals('pending_verification'));
      expect(user.serviceArea, equals('Chamkarmon, Phnom Penh'));
      expect(user.isPendingVerification, isTrue);
    });

    test('registerTechnician throws AuthException on duplicate email', () async {
      // First registration
      await authService.registerTechnician(
        fullName: 'First Tech',
        email: 'duplicate.tech@test.com',
        phoneNumber: '+85511223344',
        serviceArea: 'Daun Penh',
        password: 'password123',
      );

      // Duplicate registration attempt
      expect(
        () => authService.registerTechnician(
          fullName: 'Second Tech',
          email: 'duplicate.tech@test.com',
          phoneNumber: '+85599887766',
          serviceArea: 'Toul Kork',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('already exists'),
        )),
      );
    });

    test('registerTechnician throws AuthException on short password (< 8 chars)', () async {
      expect(
        () => authService.registerTechnician(
          fullName: 'Short Pass Tech',
          email: 'shortpass@test.com',
          phoneNumber: '+85512345678',
          serviceArea: 'Sen Sok',
          password: '123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('8 characters'),
        )),
      );
    });
  });

  group('SCRUM-66 & SCRUM-67: RegisterTechnicianScreen Widget Tests', () {
    Widget buildTestableWidget([FirebaseAuthService? service]) {
      return ProviderScope(
        overrides: [
          if (service != null)
            authServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          home: RegisterTechnicianScreen(),
        ),
      );
    }

    testWidgets('renders all required form fields and register button', (tester) async {
      final service = await createTestFirebaseAuthService();
      await tester.pumpWidget(buildTestableWidget(service));
      await tester.pumpAndSettle();

      expect(find.text('Technician Registration'), findsOneWidget);
      expect(find.text('Offer your skills'), findsOneWidget);
      expect(find.textContaining('Pending Verification status'), findsOneWidget);

      expect(find.byKey(const Key('technician_name_field')), findsOneWidget);
      expect(find.byKey(const Key('technician_email_field')), findsOneWidget);
      expect(find.byKey(const Key('technician_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('technician_service_area_field')), findsOneWidget);
      expect(find.byKey(const Key('technician_password_field')), findsOneWidget);
      expect(find.byKey(const Key('technician_confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('technician_register_button')), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty form', (tester) async {
      final service = await createTestFirebaseAuthService();
      await tester.pumpWidget(buildTestableWidget(service));
      await tester.pumpAndSettle();

      final registerButton = find.byKey(const Key('technician_register_button'));
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Service area is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('validates Cambodian phone number format correctly', (tester) async {
      final service = await createTestFirebaseAuthService();
      await tester.pumpWidget(buildTestableWidget(service));
      await tester.pumpAndSettle();

      final phoneFinder = find.byKey(const Key('technician_phone_field'));
      await tester.enterText(phoneFinder, '12345'); // Invalid phone
      final registerButton = find.byKey(const Key('technician_register_button'));
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid Cambodian phone (+855...)'), findsOneWidget);
    });

    testWidgets('validates password mismatch correctly', (tester) async {
      final service = await createTestFirebaseAuthService();
      await tester.pumpWidget(buildTestableWidget(service));
      await tester.pumpAndSettle();

      final passFinder = find.byKey(const Key('technician_password_field'));
      final confirmPassFinder = find.byKey(const Key('technician_confirm_password_field'));

      await tester.enterText(passFinder, 'password123');
      await tester.enterText(confirmPassFinder, 'differentPass');

      final registerButton = find.byKey(const Key('technician_register_button'));
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('valid form submission displays Pending Review dialog', (tester) async {
      final service = await createTestFirebaseAuthService();
      await tester.pumpWidget(buildTestableWidget(service));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('technician_name_field')), 'Rithy Kem');
      await tester.enterText(find.byKey(const Key('technician_email_field')), 'rithy.kem@test.com');
      await tester.enterText(find.byKey(const Key('technician_phone_field')), '+855 87 654 321');
      await tester.enterText(find.byKey(const Key('technician_service_area_field')), 'Toul Kork');
      await tester.enterText(find.byKey(const Key('technician_password_field')), 'password123');
      await tester.enterText(find.byKey(const Key('technician_confirm_password_field')), 'password123');

      final registerButton = find.byKey(const Key('technician_register_button'));
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);

      await tester.pumpAndSettle();

      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.byKey(const Key('technician_dialog_ok_button')), findsOneWidget);
    });
  });
}
