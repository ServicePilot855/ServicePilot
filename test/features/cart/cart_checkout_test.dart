import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/screens/booking_confirmation_screen.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/cart/providers/cart_provider.dart';
import 'package:service_pilot/features/cart/screens/cart_checkout_screen.dart';
import 'package:service_pilot/features/cart/screens/cart_screen.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

/// CART-3 (SCRUM-82) verification, subtasks SCRUM-130, SCRUM-132 and
/// SCRUM-133: the reviewed cart fills the existing request form, a valid send
/// shows a receipt for the saved booking, and a failed or invalid send shows
/// no receipt and keeps the cart.

class _OfflineBookingService extends BookingService {
  _OfflineBookingService() : super(initialBookings: []);

  @override
  Future<BookingModel> createBooking(BookingRequest request) async {
    throw StateError('offline');
  }
}

void main() {
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
    coverageAreas: ['Toul Kork'],
    isAvailable: true,
    status: 'active',
  );

  const acWash = OfferingModel(
    id: 'off-a1',
    providerId: 'prov-a',
    providerName: 'Dara Technician',
    categoryId: 'cat-ac',
    title: 'Split AC Wash',
    description: 'Standard coil and filter wash.',
    pricingMode: OfferingPricingMode.fixed,
    price: 25.0,
  );

  const gasTopUp = OfferingModel(
    id: 'off-a2',
    providerId: 'prov-a',
    providerName: 'Dara Technician',
    categoryId: 'cat-ac',
    title: 'Gas Top-up',
    description: 'Refrigerant pressure check and refill.',
    pricingMode: OfferingPricingMode.fixed,
    price: 35.5,
  );

  ProviderContainer makeContainer(BookingService bookings) {
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(homeowner),
      providerServiceProvider.overrideWithValue(
        ProviderService(initialProviders: const [providerA]),
      ),
      bookingServiceProvider.overrideWithValue(bookings),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  void seedCart(ProviderContainer container) {
    final cart = container.read(cartProvider.notifier);
    cart.addOffering(acWash, providerName: providerA.displayName);
    cart.addOffering(acWash, providerName: providerA.displayName);
    cart.addOffering(gasTopUp, providerName: providerA.displayName);
  }

  Widget buildApp(ProviderContainer container,
      {String initialRoute = CartScreen.path}) {
    final router = GoRouter(
      initialLocation: initialRoute,
      routes: [
        GoRoute(
          path: CartScreen.path,
          builder: (_, __) => const CartScreen(),
        ),
        GoRoute(
          path: CartScreen.checkoutPath,
          builder: (_, __) => const CartCheckoutScreen(),
        ),
        GoRoute(
          path: '/bookings/:bookingId/sent',
          builder: (_, state) => BookingConfirmationScreen(
            bookingId: state.pathParameters['bookingId']!,
            booking: state.extra as BookingModel?,
          ),
        ),
        GoRoute(
          path: '/categories',
          builder: (_, __) => const Scaffold(body: Text('Categories page')),
        ),
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openCheckout(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('cart_checkout_button')));
    await tester.pumpAndSettle();
  }

  Future<void> fillJobDetails(WidgetTester tester,
      {String description = 'Both units drip water and blow warm air.'}) async {
    await tester.enterText(
      find.byKey(const Key('booking_description_field')),
      description,
    );
    await tester.enterText(
      find.byKey(const Key('booking_address_field')),
      'St. 271, Toul Tom Poung, Chamkarmon',
    );
    await tapVisible(tester, find.byKey(const Key('booking_date_picker')));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('booking_time_picker')));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, Finder within) => tester
      .widgetList<Text>(find.descendant(of: within, matching: find.byType(Text)))
      .map((t) => t.data)
      .join(' | ');

  testWidgets('SCRUM-130: checkout shows the cart in place of the picker',
      (tester) async {
    setViewport(tester);
    final container = makeContainer(BookingService(initialBookings: []));
    seedCart(container);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await openCheckout(tester);

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.byKey(const Key('booking_cart_items')), findsOneWidget);
    expect(find.text('Which service do you need?'), findsNothing);
    expect(find.text('Dara Technician'), findsOneWidget);
    expect(find.text(r'2 × $25.00'), findsOneWidget);
    expect(find.text('Gas Top-up'), findsOneWidget);
    expect(find.text(r'$85.50'), findsOneWidget);
    expect(find.byKey(const Key('cart_remove_off-a1')), findsNothing,
        reason: 'the checkout summary is read-only');
    // The existing job-detail, photo, address and time fields are reused.
    expect(find.byKey(const Key('booking_description_field')), findsOneWidget);
    expect(find.byKey(const Key('booking_add_photo')), findsOneWidget);
    expect(find.byKey(const Key('booking_address_field')), findsOneWidget);
    expect(find.byKey(const Key('booking_date_picker')), findsOneWidget);
  });

  testWidgets(
      'SCRUM-131 / SCRUM-132: a valid send saves one Pending booking, '
      'shows its receipt and empties the cart', (tester) async {
    setViewport(tester);
    final bookings = BookingService(initialBookings: []);
    final container = makeContainer(bookings);
    seedCart(container);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await openCheckout(tester);
    await fillJobDetails(tester);
    await tapVisible(tester, find.byKey(const Key('booking_submit_button')));

    final saved = await bookings.getCustomerBookings('homeowner-a');
    expect(saved, hasLength(1));
    final booking = saved.single;
    expect(booking.status, BookingStatus.pending);
    expect(booking.providerId, 'prov-a');
    expect(booking.totalPrice, 85.5);
    expect(
      booking.items.map((i) => '${i.offeringId} x${i.quantity} @${i.unitPrice}'),
      ['off-a1 x2 @25.0', 'off-a2 x1 @35.5'],
    );

    expect(find.byKey(const Key('booking_request_sent_hero')), findsOneWidget);
    expect(
      textOf(tester, find.byKey(const Key('booking_sent_reference'))),
      contains(booking.id),
    );
    final services =
        textOf(tester, find.byKey(const Key('booking_sent_services')));
    expect(services, contains(r'Split AC Wash: 2 × $25.00'));
    expect(services, contains(r'Gas Top-up: $35.50'));
    expect(
      textOf(tester, find.byKey(const Key('booking_sent_total'))),
      contains(r'$85.50'),
    );
    expect(container.read(cartProvider).isEmpty, isTrue);
  });

  testWidgets('SCRUM-133: invalid job details send nothing and keep the cart',
      (tester) async {
    setViewport(tester);
    final bookings = BookingService(initialBookings: []);
    final container = makeContainer(bookings);
    seedCart(container);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await openCheckout(tester);
    await tapVisible(tester, find.byKey(const Key('booking_submit_button')));

    expect(await bookings.getCustomerBookings('homeowner-a'), isEmpty);
    expect(find.byKey(const Key('booking_request_sent_hero')), findsNothing);
    expect(find.text('Checkout'), findsOneWidget);
    expect(container.read(cartProvider).itemCount, 3);
  });

  testWidgets('SCRUM-132: a failed save shows no receipt and keeps the cart',
      (tester) async {
    setViewport(tester);
    final container = makeContainer(_OfflineBookingService());
    seedCart(container);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await openCheckout(tester);
    await fillJobDetails(tester);
    await tapVisible(tester, find.byKey(const Key('booking_submit_button')));

    expect(find.byKey(const Key('booking_request_sent_hero')), findsNothing);
    expect(
      find.text(
          "We couldn't send your request. Check your connection and try again."),
      findsOneWidget,
    );
    expect(container.read(cartProvider).itemCount, 3);
  });

  testWidgets('checkout with an empty cart shows the empty state',
      (tester) async {
    setViewport(tester);
    final container = makeContainer(BookingService(initialBookings: []));

    await tester.pumpWidget(
      buildApp(container, initialRoute: CartScreen.checkoutPath),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cart_checkout_empty')), findsOneWidget);
    expect(find.byKey(const Key('booking_submit_button')), findsNothing);
  });

  for (final locale in const [Locale('en'), Locale('km')]) {
    for (final width in const [320.0, 360.0]) {
      testWidgets(
          'checkout lays out in ${locale.languageCode} at ${width}dp and 1.3 scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final container = makeContainer(BookingService(initialBookings: []));
        seedCart(container);

        final router = GoRouter(
          initialLocation: CartScreen.checkoutPath,
          routes: [
            GoRoute(
              path: CartScreen.checkoutPath,
              builder: (_, __) => const CartCheckoutScreen(),
            ),
          ],
        );
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: locale,
            theme: AppTheme.lightTheme,
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

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('booking_cart_items')), findsOneWidget);
      });
    }
  }
}
