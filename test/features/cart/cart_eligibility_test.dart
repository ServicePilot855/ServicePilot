import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/cart/models/cart_state.dart';
import 'package:service_pilot/features/cart/providers/cart_provider.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/screens/provider_detail_screen.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const homeowner = UserModel(
    id: 'homeowner-a',
    fullName: 'Homeowner A',
    email: 'homeowner-a@example.test',
    phoneNumber: '',
    role: AppRole.homeowner,
    status: 'active',
  );

  const providerA = ProviderModel(
    id: 'prov-a',
    name: 'Dara Technician',
    type: ProviderType.independent,
    description: 'AC Specialist',
    coverageAreas: ['Toul Kork'],
    isAvailable: true,
    status: 'active',
  );

  const providerB = ProviderModel(
    id: 'prov-b',
    name: 'Sokha Plumbing',
    type: ProviderType.company,
    businessName: 'Sokha Plumbing Co.',
    description: 'Plumbing Experts',
    coverageAreas: ['Sen Sok'],
    isAvailable: true,
    status: 'active',
  );

  const providerUnavailable = ProviderModel(
    id: 'prov-unavailable',
    name: 'Busy Technician',
    type: ProviderType.independent,
    coverageAreas: ['Daun Penh'],
    isAvailable: false,
    unavailableReason: 'Fully booked today',
    status: 'active',
  );

  const fixedA1 = OfferingModel(
    id: 'off-a1',
    providerId: 'prov-a',
    providerName: 'Dara Technician',
    categoryId: 'cat-ac',
    title: 'Split AC Wash',
    description: 'Standard coil and filter wash.',
    pricingMode: OfferingPricingMode.fixed,
    price: 25.0,
    unit: 'unit',
    isActive: true,
  );

  const fixedA2 = OfferingModel(
    id: 'off-a2',
    providerId: 'prov-a',
    providerName: 'Dara Technician',
    categoryId: 'cat-ac',
    title: 'Gas Top-up',
    description: 'Refrigerant pressure check and refill.',
    pricingMode: OfferingPricingMode.fixed,
    price: 35.0,
    unit: 'unit',
    isActive: true,
  );

  const quoteA = OfferingModel(
    id: 'off-a-quote',
    providerId: 'prov-a',
    providerName: 'Dara Technician',
    categoryId: 'cat-ac',
    title: 'Inverter PCB Repair',
    description: 'Requires on-site inspection and custom quote.',
    pricingMode: OfferingPricingMode.quoteRequired,
    price: null,
    isActive: true,
  );

  const inactiveA = OfferingModel(
    id: 'off-a-inactive',
    providerId: 'prov-a',
    providerName: 'Dara Technician',
    categoryId: 'cat-ac',
    title: 'Old Service',
    description: 'No longer offered.',
    pricingMode: OfferingPricingMode.fixed,
    price: 15.0,
    isActive: false,
  );

  const fixedB1 = OfferingModel(
    id: 'off-b1',
    providerId: 'prov-b',
    providerName: 'Sokha Plumbing Co.',
    categoryId: 'cat-plumbing',
    title: 'Tap Replacement',
    description: 'Replace kitchen or bathroom faucet.',
    pricingMode: OfferingPricingMode.fixed,
    price: 20.0,
    unit: 'job',
    isActive: true,
  );

  const fixedUnavailable = OfferingModel(
    id: 'off-unavail-1',
    providerId: 'prov-unavailable',
    providerName: 'Busy Technician',
    categoryId: 'cat-ac',
    title: 'Filter Clean',
    description: 'Quick filter clean.',
    pricingMode: OfferingPricingMode.fixed,
    price: 10.0,
    isActive: true,
  );

  group('SCRUM-80 / SCRUM-125 / SCRUM-127: Cart eligibility unit tests', () {
    test('changing the signed-in homeowner clears the previous cart', () {
      final session = StateProvider<UserModel?>((ref) => homeowner);
      final container = ProviderContainer(overrides: [
        currentUserProvider.overrideWith((ref) => ref.watch(session)),
      ]);
      addTearDown(container.dispose);

      expect(
          container.read(cartProvider.notifier).addOffering(fixedA1).accepted,
          isTrue);
      container.read(session.notifier).state =
          homeowner.copyWith(fullName: 'Updated name');
      expect(container.read(cartProvider).itemCount, 1);

      container.read(session.notifier).state = null;
      expect(container.read(cartProvider).isEmpty, isTrue);
      expect(
          container.read(cartProvider.notifier).addOffering(fixedA1).accepted,
          isFalse);

      container.read(session.notifier).state =
          homeowner.copyWith(id: 'homeowner-b');
      expect(
          container.read(cartProvider.notifier).addOffering(fixedB1).accepted,
          isTrue);
      expect(container.read(cartProvider).providerId, providerB.id);
      container.read(session.notifier).state = homeowner;
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    test('first fixed-price item sets provider and adds to cart', () {
      final notifier = CartNotifier();
      final result = notifier.addOffering(fixedA1);

      expect(result.accepted, isTrue);
      expect(result.rejectionReason, isNull);
      expect(notifier.state.providerId, 'prov-a');
      expect(notifier.state.providerName, 'Dara Technician');
      expect(notifier.state.items.length, 1);
      expect(notifier.state.itemCount, 1);
      expect(notifier.state.totalPrice, 25.0);
    });

    test('eligible fixed-price item from the same provider is accepted', () {
      final notifier = CartNotifier();
      notifier.addOffering(fixedA1);
      final result = notifier.addOffering(fixedA2);

      expect(result.accepted, isTrue);
      expect(notifier.state.providerId, 'prov-a');
      expect(notifier.state.items.length, 2);
      expect(notifier.state.itemCount, 2);
      expect(notifier.state.totalPrice, 60.0);
    });

    test('adding the same fixed-price item increments quantity', () {
      final notifier = CartNotifier();
      notifier.addOffering(fixedA1);
      notifier.addOffering(fixedA1);

      expect(notifier.state.items.length, 1);
      expect(notifier.state.itemCount, 2);
      expect(notifier.state.totalPrice, 50.0);
    });

    test('item from another provider is rejected and leaves cart unchanged',
        () {
      final notifier = CartNotifier();
      notifier.addOffering(fixedA1);
      final beforeItems = List.of(notifier.state.items);

      final result = notifier.addOffering(fixedB1);

      expect(result.accepted, isFalse);
      expect(result.rejectionReason, CartAddRejectionReason.differentProvider);
      expect(result.existingProviderName, 'Dara Technician');
      expect(notifier.state.providerId, 'prov-a');
      expect(notifier.state.items, beforeItems);
      expect(notifier.state.totalPrice, 25.0);
    });

    test('quote-required item is rejected on empty or populated cart', () {
      final notifier = CartNotifier();

      final emptyResult = notifier.addOffering(quoteA);
      expect(emptyResult.accepted, isFalse);
      expect(emptyResult.rejectionReason, CartAddRejectionReason.quoteRequired);
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.providerId, isNull);

      notifier.addOffering(fixedA1);
      final populatedResult = notifier.addOffering(quoteA);
      expect(populatedResult.accepted, isFalse);
      expect(
        populatedResult.rejectionReason,
        CartAddRejectionReason.quoteRequired,
      );
      expect(notifier.state.items.length, 1);
      expect(notifier.state.totalPrice, 25.0);
    });

    test('inactive fixed-price item is rejected and leaves cart unchanged', () {
      final notifier = CartNotifier();
      notifier.addOffering(fixedA1);

      final result = notifier.addOffering(inactiveA);

      expect(result.accepted, isFalse);
      expect(result.rejectionReason, CartAddRejectionReason.inactiveOffering);
      expect(notifier.state.items.length, 1);
    });

    test('clearing cart resets provider and allows adding another provider',
        () {
      final notifier = CartNotifier();
      notifier.addOffering(fixedA1);
      notifier.clear();

      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.providerId, isNull);

      final result = notifier.addOffering(fixedB1);
      expect(result.accepted, isTrue);
      expect(notifier.state.providerId, 'prov-b');
      expect(notifier.state.totalPrice, 20.0);
    });
  });

  group('SCRUM-80 / SCRUM-126 / SCRUM-127: Provider listing Add to cart', () {
    Widget buildTestApp({
      required String initialRoute,
      Locale locale = const Locale('en'),
      double textScale = 1.0,
      ProviderContainer? container,
    }) {
      final router = GoRouter(
        initialLocation: initialRoute,
        routes: [
          GoRoute(
            path: '/providers/:providerId',
            builder: (_, state) => ProviderDetailScreen(
              providerId: state.pathParameters['providerId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/providers/:providerId/book',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Booking Page')),
            ),
          ),
        ],
      );

      final app = MaterialApp.router(
        routerConfig: router,
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          final data = MediaQuery.of(context);
          return MediaQuery(
            data: data.copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
      );

      if (container != null) {
        return UncontrolledProviderScope(
          container: container,
          child: app,
        );
      }

      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(homeowner),
          providerServiceProvider.overrideWithValue(
            ProviderService(
              initialProviders: const [
                providerA,
                providerB,
                providerUnavailable,
              ],
            ),
          ),
          offeringServiceProvider.overrideWithValue(
            OfferingService(
              initialOfferings: const [
                fixedA1,
                fixedA2,
                quoteA,
                fixedB1,
                fixedUnavailable,
              ],
            ),
          ),
        ],
        child: app,
      );
    }

    void setupViewport(WidgetTester tester, {double width = 800}) {
      tester.view.physicalSize = Size(width, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('adds eligible fixed-price items from the same provider',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(buildTestApp(initialRoute: '/providers/prov-a'));
      await tester.pumpAndSettle();

      // Quote-required offering does not expose Add to cart
      expect(
          find.byKey(const Key('btn_add_to_cart_off-a-quote')), findsNothing);
      expect(find.byKey(const Key('btn_quote_off-a-quote')), findsOneWidget);

      // Add first fixed-price service
      await tester.tap(find.byKey(const Key('btn_add_to_cart_off-a1')));
      await tester.pumpAndSettle();

      expect(find.text('Added Split AC Wash to cart.'), findsOneWidget);
      expect(
          find.byKey(const Key('provider_detail_cart_badge')), findsOneWidget);
      expect(find.text('Cart (1)'), findsOneWidget);
      expect(
        find.text('Cart has 1 service from Dara Technician.'),
        findsOneWidget,
      );

      // Add second fixed-price service from the same provider
      await tester.tap(find.byKey(const Key('btn_add_to_cart_off-a2')));
      await tester.pumpAndSettle();

      expect(find.text('Added Gas Top-up to cart.'), findsOneWidget);
      expect(find.text('Cart (2)'), findsOneWidget);
      expect(
        find.text('Cart has 2 services from Dara Technician.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'rejects item from another provider, leaves cart unchanged, and shows explanation',
        (tester) async {
      setupViewport(tester);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(homeowner),
          providerServiceProvider.overrideWithValue(
            ProviderService(
              initialProviders: const [providerA, providerB],
            ),
          ),
          offeringServiceProvider.overrideWithValue(
            OfferingService(
              initialOfferings: const [fixedA1, fixedB1],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Seed cart with provider A's service
      container
          .read(cartProvider.notifier)
          .addOffering(fixedA1, providerName: providerA.displayName);

      await tester.pumpWidget(
        buildTestApp(
          initialRoute: '/providers/prov-b',
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_add_to_cart_off-b1')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Your cart already has services from Dara Technician. Clear your cart before adding from another provider.',
        ),
        findsOneWidget,
      );
      expect(container.read(cartProvider).providerId, 'prov-a');
      expect(container.read(cartProvider).items.length, 1);
      expect(container.read(cartProvider).items.first.offering.id, 'off-a1');
    });

    testWidgets('disables Add to cart when provider cannot accept bookings',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(
        buildTestApp(initialRoute: '/providers/prov-unavailable'),
      );
      await tester.pumpAndSettle();

      final buttonFinder =
          find.byKey(const Key('btn_add_to_cart_off-unavail-1'));
      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<OutlinedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('renders Khmer Add to cart at 360dp and 130% text scale',
        (tester) async {
      setupViewport(tester, width: 360);
      await tester.pumpWidget(
        buildTestApp(
          initialRoute: '/providers/prov-a',
          locale: const Locale('km'),
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('បន្ថែមទៅកន្ត្រក'), findsWidgets);
    });
  });
}
