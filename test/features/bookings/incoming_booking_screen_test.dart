import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/router/app_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/providers/services/company_profile_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';
import 'package:service_pilot/shared/home/customer_home.dart';

class _SignedIn extends AuthNotifier {
  _SignedIn(this.user);

  final UserModel user;

  @override
  AuthState build() => AuthStateAuthenticated(user);
}

void main() {
  const inbox = '/booking-requests';
  final appointment = DateTime(2026, 12, 1, 10);
  BookingModel request(String id, String providerId, String title) =>
      BookingModel(
        id: id,
        customerId: 'customer',
        providerId: providerId,
        providerName: 'Test provider',
        serviceCategory: 'Plumbing',
        serviceTitle: title,
        description: 'The sink leaks below the trap.',
        address: 'Private street address',
        preferredDateTime: appointment,
        createdAt: appointment,
        photoUrls: const ['https://example.test/private.jpg'],
      );

  Future<void> openApp(
    WidgetTester tester,
    AppRole role,
    String providerId,
    String path, {
    Locale locale = const Locale('en'),
    double width = 360,
    bool hasRequest = true,
  }) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = BookingService(initialBookings: [
      if (hasRequest) request('owned', providerId, 'Sink repair'),
      request('other', 'another-provider', 'Water pump repair'),
    ]);
    final user = UserModel(
      id: providerId,
      fullName: 'Service Provider',
      email: 'provider@example.test',
      phoneNumber: '',
      role: role,
      status: 'active',
      companyId: role == AppRole.company ? providerId : null,
    );
    final container = ProviderContainer(overrides: [
      authProvider.overrideWith(() => _SignedIn(user)),
      bookingServiceProvider.overrideWithValue(service),
      companyProfileServiceProvider.overrideWithValue(
        CompanyProfileService(firestore: FakeFirebaseFirestore()),
      ),
    ]);
    final router = container.read(appRouterProvider);
    addTearDown(service.dispose);
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    router.go(path);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  for (final (role, locale, width) in [
    (AppRole.independentProvider, const Locale('en'), 360.0),
    (AppRole.company, const Locale('km'), 320.0),
  ]) {
    testWidgets('${role.value} opens only its own request', (tester) async {
      await openApp(tester, role, 'provider', role.homeRoute,
          locale: locale, width: width);
      final homeContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(homeContext)!;
      final button = find.text(
          locale.languageCode == 'en' ? 'Incoming requests' : 'សំណើកក់ចូល');
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Water pump repair'), findsNothing);
      await tester.tap(find.text('Sink repair'));
      await tester.pumpAndSettle();
      expect(find.text('The sink leaks below the trap.'), findsOneWidget);
      expect(find.text(l10n.bookingSummaryWhen), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
      expect(find.textContaining('Private street address'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a different provider request cannot be opened by URL',
      (tester) async {
    await openApp(
        tester, AppRole.independentProvider, 'provider', '$inbox/other');
    expect(find.text('This booking request is unavailable.'), findsOneWidget);
    expect(find.text('Water pump repair'), findsNothing);
  });

  testWidgets('a homeowner is redirected from the inbox URL', (tester) async {
    await openApp(tester, AppRole.homeowner, 'customer', '$inbox/owned');
    expect(find.byType(CustomerHome), findsOneWidget);
    expect(find.text('The sink leaks below the trap.'), findsNothing);
  });

  testWidgets('a provider with no addressed requests sees the empty state', (
    tester,
  ) async {
    await openApp(tester, AppRole.company, 'provider', inbox, hasRequest: false);
    expect(find.text('You have no pending booking requests.'), findsOneWidget);
    expect(find.text('Water pump repair'), findsNothing);
  });
}
