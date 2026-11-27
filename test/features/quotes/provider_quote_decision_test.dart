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
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/providers/services/company_profile_service.dart';
import 'package:service_pilot/features/providers/services/independent_profile_service.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/features/quotes/providers/quote_provider.dart';
import 'package:service_pilot/features/quotes/services/quote_service.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

class _SignedIn extends AuthNotifier {
  _SignedIn(this.user);
  final UserModel user;

  @override
  AuthState build() => AuthStateAuthenticated(user);
}

QuoteRequestModel _quote({
  required String id,
  required String providerId,
  String providerName = 'Dara Chhum',
  String customerName = 'Sophea Meas',
  String offeringTitle = 'Central Inverter PCB Diagnosis',
  String description = 'Inverter board clicks repeatedly and blinks E5.',
  QuoteStatus status = QuoteStatus.approved,
  double? quotedPrice = 85.0,
}) {
  return QuoteRequestModel(
    id: id,
    customerId: 'customer-1',
    customerName: customerName,
    providerId: providerId,
    providerName: providerName,
    offeringId: 'off-quote-1',
    offeringTitle: offeringTitle,
    description: description,
    status: status,
    quotedPrice: quotedPrice,
    createdAt: DateTime(2026, 11, 27, 9, 0),
    updatedAt: DateTime(2026, 11, 27, 10, 30),
  );
}

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required String path,
    required UserModel user,
    required List<QuoteRequestModel> quotes,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    double width = 360,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final quoteService = InMemoryQuoteService(initialQuotes: quotes);
    final bookingService = BookingService();
    final offeringService = OfferingService();
    final fakeFirestore = FakeFirebaseFirestore();

    final container = ProviderContainer(overrides: [
      authProvider.overrideWith(() => _SignedIn(user)),
      quoteServiceProvider.overrideWithValue(quoteService),
      bookingServiceProvider.overrideWithValue(bookingService),
      offeringServiceProvider.overrideWithValue(offeringService),
      companyProfileServiceProvider.overrideWithValue(
        CompanyProfileService(firestore: fakeFirestore),
      ),
      independentProfileServiceProvider.overrideWithValue(
        IndependentProfileService(firestore: fakeFirestore),
      ),
    ]);

    final router = container.read(appRouterProvider);
    addTearDown(bookingService.dispose);
    addTearDown(container.dispose);
    addTearDown(router.dispose);

    router.go(path);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  UserModel independentUser({
    String id = 'prov-ind-1',
    String status = 'active',
  }) =>
      UserModel(
        id: id,
        fullName: 'Dara Chhum',
        email: 'dara@example.test',
        phoneNumber: '+85512345678',
        role: AppRole.independentProvider,
        status: status,
      );

  UserModel companyAdminUser({
    String id = 'prov-co-1',
    String? companyId,
    String status = 'active',
  }) =>
      UserModel(
        id: id,
        fullName: 'Sokha Lim',
        email: 'admin@fixco.test',
        phoneNumber: '+85512999888',
        role: AppRole.company,
        status: status,
        companyId: companyId ?? id,
        companyName: 'Phnom Penh Fix Co.',
      );

  group('SCRUM-88 / QUOTE-7: Independent provider quote decisions', () {
    testWidgets(
      'displays approved and rejected quote prices and decisions on home and detail',
      (tester) async {
        final quotes = [
          _quote(
            id: 'q-approved',
            providerId: 'prov-ind-1',
            offeringTitle: 'Central Inverter PCB Diagnosis',
            status: QuoteStatus.approved,
            quotedPrice: 85.0,
          ),
          _quote(
            id: 'q-rejected',
            providerId: 'prov-ind-1',
            offeringTitle: 'Main Breaker Panel Inspection',
            status: QuoteStatus.rejected,
            quotedPrice: 140.5,
          ),
          _quote(
            id: 'q-other',
            providerId: 'prov-other',
            offeringTitle: 'Other Provider Secret Quote',
            description: 'Secret description for another provider only.',
            status: QuoteStatus.approved,
            quotedPrice: 999.0,
          ),
        ];

        await pumpApp(
          tester,
          path: AppRole.independentProvider.homeRoute,
          user: independentUser(),
          quotes: quotes,
        );

        // Owned quotes with price & decision are visible.
        expect(find.byKey(const Key('provider_quote_card_q-approved')), findsOneWidget);
        expect(find.byKey(const Key('provider_quote_card_q-rejected')), findsOneWidget);
        expect(find.text('\$85.00'), findsOneWidget);
        expect(find.text('\$140.50'), findsOneWidget);
        expect(find.text('Approved'), findsOneWidget);
        expect(find.text('Rejected'), findsOneWidget);

        // Other provider's quote is not shown.
        expect(find.byKey(const Key('provider_quote_card_q-other')), findsNothing);
        expect(find.text('Other Provider Secret Quote'), findsNothing);
        expect(find.text('\$999.00'), findsNothing);

        // Open approved quote detail.
        await tester.ensureVisible(
          find.byKey(const Key('provider_quote_card_q-approved')),
        );
        await tester.tap(
          find.byKey(const Key('provider_quote_card_q-approved')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('provider_quote_detail_status_badge')), findsOneWidget);
        expect(find.byKey(const Key('provider_quote_detail_price')), findsOneWidget);
        expect(find.text('\$85.00'), findsOneWidget);
        expect(
          find.text('The homeowner approved your quoted price.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'blocks direct navigation to another provider quote detail',
      (tester) async {
        final quotes = [
          _quote(
            id: 'q-other',
            providerId: 'prov-other',
            offeringTitle: 'Other Provider Secret Quote',
            description: 'Secret description for another provider only.',
            status: QuoteStatus.approved,
            quotedPrice: 999.0,
          ),
        ];

        await pumpApp(
          tester,
          path: '/provider/quotes/q-other',
          user: independentUser(),
          quotes: quotes,
        );

        expect(
          find.byKey(const Key('provider_quote_inaccessible_notice')),
          findsOneWidget,
        );
        expect(find.text('Other Provider Secret Quote'), findsNothing);
        expect(find.text('\$999.00'), findsNothing);
      },
    );
  });

  group('SCRUM-88 / QUOTE-7: Service company administrator quote decisions', () {
    testWidgets(
      'displays approved and rejected quote decisions for company admin and isolates other providers',
      (tester) async {
        final quotes = [
          _quote(
            id: 'q-co-approved',
            providerId: 'prov-co-1',
            providerName: 'Phnom Penh Fix Co.',
            offeringTitle: 'Commercial Rewiring Survey',
            status: QuoteStatus.approved,
            quotedPrice: 250.0,
          ),
          _quote(
            id: 'q-co-rejected',
            providerId: 'prov-co-1',
            providerName: 'Phnom Penh Fix Co.',
            offeringTitle: 'Roof Tank Replacement',
            status: QuoteStatus.rejected,
            quotedPrice: 310.0,
          ),
          _quote(
            id: 'q-other',
            providerId: 'prov-ind-1',
            offeringTitle: 'Independent Only Quote',
            status: QuoteStatus.approved,
            quotedPrice: 75.0,
          ),
        ];

        await pumpApp(
          tester,
          path: AppRole.company.homeRoute,
          user: companyAdminUser(),
          quotes: quotes,
        );

        expect(find.byKey(const Key('provider_quote_card_q-co-approved')), findsOneWidget);
        expect(find.byKey(const Key('provider_quote_card_q-co-rejected')), findsOneWidget);
        expect(find.text('\$250.00'), findsOneWidget);
        expect(find.text('\$310.00'), findsOneWidget);
        expect(find.byKey(const Key('provider_quote_card_q-other')), findsNothing);

        // Open rejected quote detail.
        await tester.ensureVisible(
          find.byKey(const Key('provider_quote_card_q-co-rejected')),
        );
        await tester.tap(
          find.byKey(const Key('provider_quote_card_q-co-rejected')),
        );
        await tester.pumpAndSettle();

        expect(find.text('\$310.00'), findsOneWidget);
        expect(find.text('Rejected'), findsAtLeastNWidgets(1));
        expect(
          find.text('The homeowner declined your quoted price.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'prevents company technicians and homeowners from opening provider quote detail',
      (tester) async {
        final quotes = [
          _quote(
            id: 'q-co-approved',
            providerId: 'prov-co-1',
            offeringTitle: 'Commercial Rewiring Survey',
            status: QuoteStatus.approved,
            quotedPrice: 250.0,
          ),
        ];

        const companyTech = UserModel(
          id: 'tech-1',
          fullName: 'Company Tech',
          email: 'tech@fixco.test',
          phoneNumber: '+85512000111',
          role: AppRole.companyTechnician,
          status: 'active',
          companyId: 'prov-co-1',
        );

        await pumpApp(
          tester,
          path: '/provider/quotes/q-co-approved',
          user: companyTech,
          quotes: quotes,
        );

        // Router redirects company technician away from /provider/quotes/* to their home.
        expect(find.text('Commercial Rewiring Survey'), findsNothing);
        expect(find.text('\$250.00'), findsNothing);
      },
    );

    testWidgets(
      'renders cleanly in Khmer at 360dp with 130% text scaling',
      (tester) async {
        final quotes = [
          _quote(
            id: 'q-km-1',
            providerId: 'prov-ind-1',
            offeringTitle: 'ជួសជុលម៉ាស៊ីនត្រជាក់ Central Inverter',
            status: QuoteStatus.approved,
            quotedPrice: 95.0,
          ),
        ];

        await pumpApp(
          tester,
          path: '/provider/quotes/q-km-1',
          user: independentUser(),
          quotes: quotes,
          locale: const Locale('km'),
          textScale: 1.3,
          width: 360,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('\$95.00'), findsOneWidget);
        expect(find.byKey(const Key('provider_quote_detail_status_badge')), findsOneWidget);
      },
    );

    testWidgets(
      'resolves seeded provider ID for technician@test.com on home and detail',
      (tester) async {
        const seededTech = UserModel(
          id: 'auth-uid-virak',
          fullName: 'Virak Chan',
          email: 'technician@test.com',
          phoneNumber: '+85512345678',
          role: AppRole.independentProvider,
          status: 'active',
        );
        final quotes = [
          _quote(
            id: 'q-virak-1',
            providerId: 'prov-virak-ac',
            providerName: 'Virak Chan',
            offeringTitle: 'Split AC Leak Diagnosis',
            status: QuoteStatus.approved,
            quotedPrice: 55.0,
          ),
        ];

        await pumpApp(
          tester,
          path: AppRole.independentProvider.homeRoute,
          user: seededTech,
          quotes: quotes,
        );

        expect(find.byKey(const Key('provider_quote_card_q-virak-1')), findsOneWidget);
        expect(find.text('\$55.00'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const Key('provider_quote_card_q-virak-1')),
        );
        await tester.tap(
          find.byKey(const Key('provider_quote_card_q-virak-1')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('provider_quote_detail_price')), findsOneWidget);
        expect(find.text('\$55.00'), findsOneWidget);
      },
    );
  });
}
