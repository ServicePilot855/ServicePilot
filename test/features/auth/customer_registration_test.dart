import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_service.dart';
import 'package:service_pilot/core/auth/firebase_auth_service.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/auth/screens/register_customer_screen.dart';

import '../../helpers/test_firebase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SCRUM-40 / US-01: Customer Model & Auth Service Unit Tests', () {
    late FakeFirebaseAuth fakeAuth;
    late FirebaseAuthService authService;

    setUp(() async {
      fakeAuth = FakeFirebaseAuth();
      authService = await createTestFirebaseAuthService(fakeAuth: fakeAuth);
    });

    test('UserModel supports Customer/Homeowner role and JSON serialization', () {
      final now = DateTime.now();
      final user = UserModel(
        id: 'cust-101',
        fullName: 'Sok Dara',
        email: 'dara.sok@test.com',
        phoneNumber: '+85512345678',
        role: AppRole.homeowner,
        status: 'active',
        createdAt: now,
      );

      expect(user.role, equals(AppRole.homeowner));
      expect(user.role.displayName, equals('Customer'));
      expect(user.status, equals('active'));
      expect(user.isPendingVerification, isFalse);

      // Test JSON roundtrip
      final json = user.toJson();
      expect(json['role'], equals('homeowner'));
      expect(json['status'], equals('active'));

      final fromJson = UserModel.fromJson(json);
      expect(fromJson.id, equals(user.id));
      expect(fromJson.fullName, equals('Sok Dara'));
      expect(fromJson.email, equals(user.email));
      expect(fromJson.phoneNumber, equals(user.phoneNumber));
      expect(fromJson.role, equals(AppRole.homeowner));
    });

    test('registerCustomer creates customer account with active status', () async {
      final user = await authService.registerCustomer(
        fullName: 'Dara Sok',
        email: 'dara.unique.reg@test.com',
        phoneNumber: '+85512345678',
        password: 'password123',
      );

      expect(user.fullName, equals('Dara Sok'));
      expect(user.email, equals('dara.unique.reg@test.com'));
      expect(user.phoneNumber, equals('+85512345678'));
      expect(user.role, equals(AppRole.homeowner));
      expect(user.status, equals('active'));
    });

    test('registerCustomer throws AuthException on duplicate email', () async {
      await authService.registerCustomer(
        fullName: 'Original User',
        email: 'duplicate.cust@test.com',
        phoneNumber: '+85512345678',
        password: 'password123',
      );

      expect(
        () => authService.registerCustomer(
          fullName: 'Duplicate User',
          email: 'duplicate.cust@test.com',
          phoneNumber: '+85598765432',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('already exists'),
        )),
      );
    });

    test('registerCustomer throws AuthException on short password (< 8 chars)', () async {
      expect(
        () => authService.registerCustomer(
          fullName: 'Short Pass',
          email: 'shortpass.cust@test.com',
          phoneNumber: '+85512345678',
          password: 'short',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('at least 8 characters'),
        )),
      );
    });
  });

  group('SCRUM-58 & SCRUM-62: Customer Registration UI & Validation Widget Tests', () {
    Widget createWidgetUnderTest([FirebaseAuthService? service]) {
      return ProviderScope(
        overrides: [
          if (service != null)
            authServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          home: RegisterCustomerScreen(),
        ),
      );
    }

    Future<void> pumpScreen(WidgetTester tester) async {
      final service = await createTestFirebaseAuthService();
      await tester.pumpWidget(createWidgetUnderTest(service));
      await tester.pumpAndSettle();
    }

    Future<void> fillDetails(
      WidgetTester tester, {
      String name = 'Sok Heng',
      String email = 'sok.heng.new@test.com',
      String phone = '+85512345678',
    }) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), name);
      await tester.enterText(fields.at(1), email);
      await tester.enterText(fields.at(2), phone);
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    testWidgets('details page shows only the personal details', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Customer Registration'), findsOneWidget);
      expect(find.text('Book repair services'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Phone Number (Cambodia)'), findsOneWidget);
      expect(find.text('Sign up with Google'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);

      expect(find.text('Password'), findsNothing);
      expect(find.text('Create Account'), findsNothing);
    });

    testWidgets('Continue with empty details shows each required error', (tester) async {
      await pumpScreen(tester);
      await tapText(tester, 'Continue');

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Set up your password'), findsNothing);
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await pumpScreen(tester);
      await fillDetails(tester, email: 'not-an-email');
      await tapText(tester, 'Continue');

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error for invalid Cambodian phone format', (tester) async {
      await pumpScreen(tester);
      await fillDetails(tester, phone: '12345');
      await tapText(tester, 'Continue');

      expect(find.text('Enter a valid Cambodian phone (+855...)'), findsOneWidget);
    });

    testWidgets('valid details open the password page, and Back keeps them', (tester) async {
      await pumpScreen(tester);
      await fillDetails(tester);
      await tapText(tester, 'Continue');

      expect(find.text('Set up your password'), findsOneWidget);
      expect(find.textContaining('sok.heng.new@test.com'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('3 of 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Book repair services'), findsOneWidget);
      expect(find.text('Sok Heng'), findsOneWidget);
    });

    testWidgets('password page requires a password', (tester) async {
      await pumpScreen(tester);
      await fillDetails(tester);
      await tapText(tester, 'Continue');
      await tapText(tester, 'Create Account');

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await pumpScreen(tester);
      await fillDetails(tester);
      await tapText(tester, 'Continue');

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'password123');
      await tester.enterText(fields.at(1), 'differentPassword');
      await tapText(tester, 'Create Account');

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows success sheet upon submitting valid registration info', (tester) async {
      await pumpScreen(tester);
      await fillDetails(tester);
      await tapText(tester, 'Continue');

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'password123');
      await tester.enterText(fields.at(1), 'password123');
      await tapText(tester, 'Create Account');

      expect(find.text('Account Created!'), findsOneWidget);
      expect(find.text('Go to Login'), findsOneWidget);
    });
  });
}
