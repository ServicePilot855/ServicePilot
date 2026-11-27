import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/screens/provider_detail_screen.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';
import 'package:service_pilot/features/services/widgets/provider_offering_list.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testProvider = ProviderModel(
    id: 'prov-test-1',
    name: 'Dara Technician',
    type: ProviderType.independent,
    description: 'Expert Cooling Technician',
    bio: '7+ years repairing air conditioning and cooling equipment.',
    specialties: ['Inverter Diagnostics'],
    coverageAreas: ['Toul Kork'],
    isAvailable: true,
    status: 'active',
  );

  final testOfferings = [
    const OfferingModel(
      id: 'off-fixed-1',
      providerId: 'prov-test-1',
      providerName: 'Dara Technician',
      categoryId: 'cat-ac',
      title: 'Split Coil Deep Wash',
      description: 'Standard coil wash and drain cleaning.',
      pricingMode: OfferingPricingMode.fixed,
      price: 25.0,
      unit: 'unit',
      isActive: true,
    ),
    const OfferingModel(
      id: 'off-quote-1',
      providerId: 'prov-test-1',
      providerName: 'Dara Technician',
      categoryId: 'cat-ac',
      title: 'Central Inverter PCB Diagnosis',
      description: 'Micro-soldering diagnostics requiring custom on-site quote.',
      pricingMode: OfferingPricingMode.quoteRequired,
      price: null,
      isActive: true,
    ),
  ];

  Widget buildDetailApp({
    required List<OfferingModel> offerings,
    void Function(String route)? onNavigated,
  }) {
    final router = GoRouter(
      initialLocation: '/providers/prov-test-1',
      routes: [
        GoRoute(
          path: '/providers/:providerId',
          builder: (_, state) => const ProviderDetailScreen(
            providerId: 'prov-test-1',
            initialProvider: testProvider,
          ),
        ),
        GoRoute(
          path: '/providers/:providerId/book',
          builder: (_, state) {
            onNavigated?.call('/providers/prov-test-1/book');
            return const Scaffold(body: Center(child: Text('Booking Page')));
          },
        ),
        GoRoute(
          path: '/providers/:providerId/quote',
          builder: (_, state) {
            onNavigated?.call('/providers/prov-test-1/quote');
            return const Scaffold(body: Center(child: Text('Quote Page')));
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        providerServiceProvider.overrideWithValue(
          ProviderService(initialProviders: [testProvider]),
        ),
        offeringServiceProvider.overrideWithValue(
          OfferingService(initialOfferings: offerings),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  void setupViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('SCRUM-77 / SCRUM-120: Verify Quote Classification & Cart Exclusion', () {
    test('Offering cart exclusion logic verified at model level', () {
      final fixed = testOfferings.first;
      final quote = testOfferings.last;

      // Fixed price can be added to checkout cart
      expect(fixed.isFixedPrice, isTrue);
      expect(fixed.canAddToCart, isTrue);
      expect(fixed.requiresQuoteIntake, isFalse);

      // Quote required CANNOT enter standard fixed cart checkout
      expect(quote.isQuoteRequired, isTrue);
      expect(quote.canAddToCart, isFalse);
      expect(quote.requiresQuoteIntake, isTrue);
    });

    testWidgets(
        'Homeowner sees "Quote Required" designation and cart exclusion notice',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(buildDetailApp(offerings: testOfferings));
      await tester.pumpAndSettle();

      // Verify Offerings Section header (uses l10n key providerOfferingsSection)
      expect(find.text('Available Services & Offerings'), findsOneWidget);

      // Verify Fixed Price offering shows price and Book button
      expect(find.text('Split Coil Deep Wash'), findsOneWidget);
      expect(find.text('\$25.00 / unit'), findsOneWidget);
      expect(find.byKey(const Key('btn_book_off-fixed-1')), findsOneWidget);

      // Verify Quote Required offering displays Quote Required badge
      expect(find.text('Central Inverter PCB Diagnosis'), findsOneWidget);
      expect(find.byKey(const Key('badge_quote_off-quote-1')), findsOneWidget);

      // Verify Cart Exclusion message is present
      expect(
        find.text('Excluded from direct cart checkout'),
        findsOneWidget,
      );

      // Verify CTA button says "Request a Quote"
      expect(
        find.byKey(const Key('btn_quote_off-quote-1')),
        findsOneWidget,
      );
      expect(find.text('Request a Quote'), findsOneWidget);
    });

    testWidgets(
        'Tapping "Request a Quote" launches quote request intake',
        (tester) async {
      setupViewport(tester);
      String? navigatedRoute;
      await tester.pumpWidget(buildDetailApp(
        offerings: testOfferings,
        onNavigated: (route) => navigatedRoute = route,
      ));
      await tester.pumpAndSettle();

      // Tap Request a Quote
      await tester.tap(find.byKey(const Key('btn_quote_off-quote-1')));
      await tester.pumpAndSettle();

      // Navigated to separate quote request intake
      expect(navigatedRoute, '/providers/prov-test-1/quote');
    });

    testWidgets('Provider dashboard displays quote badge for published offerings',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offeringServiceProvider.overrideWithValue(
              OfferingService(initialOfferings: testOfferings),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: ProviderOfferingList(
                  providerId: 'prov-test-1',
                  providerName: 'Dara Technician',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Service Offerings'), findsOneWidget);
      expect(find.byKey(const Key('add_offering_button')), findsOneWidget);
      expect(find.byKey(const Key('badge_quote_required_off-quote-1')),
          findsOneWidget);
    });
  });

  group('SCRUM-74 (DISC-1): View provider service details and prices', () {
    testWidgets(
        'AC: inactive offerings (isActive: false) are NOT shown on provider profile',
        (tester) async {
      setupViewport(tester);

      // One active + one inactive offering for the same provider
      final mixedOfferings = [
        const OfferingModel(
          id: 'off-active-1',
          providerId: 'prov-test-1',
          providerName: 'Dara Technician',
          categoryId: 'cat-ac',
          title: 'Active Service',
          description: 'This service is currently active.',
          pricingMode: OfferingPricingMode.fixed,
          price: 30.0,
          unit: 'unit',
          isActive: true,
        ),
        const OfferingModel(
          id: 'off-inactive-1',
          providerId: 'prov-test-1',
          providerName: 'Dara Technician',
          categoryId: 'cat-ac',
          title: 'Discontinued Service',
          description: 'This service is no longer offered.',
          pricingMode: OfferingPricingMode.fixed,
          price: 15.0,
          unit: 'unit',
          isActive: false,
        ),
      ];

      await tester.pumpWidget(buildDetailApp(offerings: mixedOfferings));
      await tester.pumpAndSettle();

      // Active offering is visible
      expect(find.text('Active Service'), findsOneWidget);
      expect(find.text('\$30.00 / unit'), findsOneWidget);

      // Inactive offering must NOT appear on the customer profile view
      expect(find.text('Discontinued Service'), findsNothing);
      expect(find.text('\$15.00 / unit'), findsNothing);
    });

    testWidgets(
        'AC: offerings from other providers are NOT shown on this provider\'s profile',
        (tester) async {
      setupViewport(tester);

      // prov-test-1's own offering + a different provider's offering in service store
      final crossProviderOfferings = [
        const OfferingModel(
          id: 'off-mine-1',
          providerId: 'prov-test-1',
          providerName: 'Dara Technician',
          categoryId: 'cat-ac',
          title: 'My Own Service',
          description: 'Belongs to prov-test-1.',
          pricingMode: OfferingPricingMode.fixed,
          price: 25.0,
          unit: 'unit',
          isActive: true,
        ),
        const OfferingModel(
          id: 'off-other-1',
          providerId: 'prov-other-99',
          providerName: 'Other Provider',
          categoryId: 'cat-ac',
          title: 'Other Provider Service',
          description: 'Belongs to a different provider.',
          pricingMode: OfferingPricingMode.fixed,
          price: 50.0,
          unit: 'job',
          isActive: true,
        ),
      ];

      await tester.pumpWidget(buildDetailApp(offerings: crossProviderOfferings));
      await tester.pumpAndSettle();

      // Own offering is visible
      expect(find.text('My Own Service'), findsOneWidget);

      // Other provider's offering must NOT appear on this profile
      expect(find.text('Other Provider Service'), findsNothing);
      expect(find.text('\$50.00 / job'), findsNothing);
    });

    testWidgets(
        'AC: provider profile shows no offerings section when provider has none',
        (tester) async {
      setupViewport(tester);

      // No offerings for prov-test-1
      await tester.pumpWidget(buildDetailApp(offerings: const []));
      await tester.pumpAndSettle();

      // The offerings section header should not appear
      expect(find.text('Available Services & Offerings'), findsNothing);
    });

    testWidgets(
        'AC: each offering shows service title, description, and price from listing',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(buildDetailApp(offerings: testOfferings));
      await tester.pumpAndSettle();

      // Fixed offering: title, description, and priceDisplay from the listing
      expect(find.text('Split Coil Deep Wash'), findsOneWidget);
      expect(
        find.text('Standard coil wash and drain cleaning.'),
        findsOneWidget,
      );
      expect(find.text('\$25.00 / unit'), findsOneWidget);

      // Quote offering: title, description visible; quote badge instead of price
      expect(find.text('Central Inverter PCB Diagnosis'), findsOneWidget);
      expect(
        find.text('Micro-soldering diagnostics requiring custom on-site quote.'),
        findsOneWidget,
      );
      // Price label NOT shown for quote offerings
      expect(find.text('Quote Required'), findsOneWidget); // badge text
    });
  });
}
