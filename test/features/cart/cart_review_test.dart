import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/cart/providers/cart_provider.dart';
import 'package:service_pilot/features/cart/screens/cart_screen.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/screens/provider_detail_screen.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

/// CART-2 (SCRUM-81) verification, subtask SCRUM-129: the cart shows its
/// provider, each item's fixed price and the computed total, and an empty
/// cart shows an empty state.
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
    unit: 'unit',
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
    unit: 'unit',
  );

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(homeowner),
      providerServiceProvider.overrideWithValue(
        ProviderService(initialProviders: const [providerA]),
      ),
      offeringServiceProvider.overrideWithValue(
        OfferingService(initialOfferings: const [acWash, gasTopUp]),
      ),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Widget buildApp(
    ProviderContainer container, {
    String initialRoute = CartScreen.path,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) {
    final router = GoRouter(
      initialLocation: initialRoute,
      routes: [
        GoRoute(
          path: CartScreen.path,
          builder: (_, __) => const CartScreen(),
        ),
        GoRoute(
          path: '/categories',
          builder: (_, __) => const Scaffold(body: Text('Categories page')),
        ),
        GoRoute(
          path: '/providers/:providerId',
          builder: (_, state) => ProviderDetailScreen(
            providerId: state.pathParameters['providerId'] ?? '',
          ),
        ),
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
  }

  void setViewport(WidgetTester tester, {double width = 400}) {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  group('SCRUM-128 / SCRUM-129: cart summary', () {
    testWidgets('a two-service cart shows provider, each price and the total',
        (tester) async {
      setViewport(tester);
      final container = makeContainer();
      final cart = container.read(cartProvider.notifier);
      cart.addOffering(acWash, providerName: providerA.displayName);
      cart.addOffering(gasTopUp, providerName: providerA.displayName);

      await tester.pumpWidget(buildApp(container));
      await tester.pumpAndSettle();

      expect(find.text('Review your cart'), findsOneWidget);
      expect(find.text('2 services'), findsOneWidget);
      expect(find.text('Provider'), findsOneWidget);
      expect(find.text('Dara Technician'), findsOneWidget);

      expect(find.text('Split AC Wash'), findsOneWidget);
      expect(textOf(tester, 'cart_item_price_off-a1'), r'$25.00');
      expect(textOf(tester, 'cart_item_subtotal_off-a1'), r'$25.00');

      expect(find.text('Gas Top-up'), findsOneWidget);
      expect(textOf(tester, 'cart_item_price_off-a2'), r'$35.50');
      expect(textOf(tester, 'cart_item_subtotal_off-a2'), r'$35.50');

      expect(find.text('Total'), findsOneWidget);
      expect(textOf(tester, 'cart_total_value'), r'$60.50');
      expect(container.read(cartProvider).totalPrice, 60.5);
      expect(find.byKey(const Key('cart_empty_state')), findsNothing);
    });

    testWidgets('a repeated service shows quantity, unit price and line total',
        (tester) async {
      setViewport(tester);
      final container = makeContainer();
      final cart = container.read(cartProvider.notifier);
      cart.addOffering(acWash);
      cart.addOffering(acWash);
      cart.addOffering(gasTopUp);

      await tester.pumpWidget(buildApp(container));
      await tester.pumpAndSettle();

      expect(find.text('3 services'), findsOneWidget);
      expect(textOf(tester, 'cart_item_price_off-a1'), r'2 × $25.00');
      expect(textOf(tester, 'cart_item_subtotal_off-a1'), r'$50.00');
      expect(textOf(tester, 'cart_total_value'), r'$85.50');
    });

    testWidgets('removing items updates the total, then shows the empty state',
        (tester) async {
      setViewport(tester);
      final container = makeContainer();
      final cart = container.read(cartProvider.notifier);
      cart.addOffering(acWash);
      cart.addOffering(gasTopUp);

      await tester.pumpWidget(buildApp(container));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cart_remove_off-a2')));
      await tester.pumpAndSettle();
      expect(find.text('Gas Top-up'), findsNothing);
      expect(textOf(tester, 'cart_total_value'), r'$25.00');

      await tester.tap(find.byTooltip('Remove Split AC Wash'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cart_empty_state')), findsOneWidget);
      expect(container.read(cartProvider).providerId, isNull);
    });

    testWidgets('an empty cart shows the empty state and a way to browse',
        (tester) async {
      setViewport(tester);
      final container = makeContainer();

      await tester.pumpWidget(buildApp(container));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cart_empty_state')), findsOneWidget);
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.byKey(const Key('cart_total')), findsNothing);
      expect(find.byKey(const Key('cart_provider')), findsNothing);

      await tester.tap(find.byKey(const Key('cart_browse_services')));
      await tester.pumpAndSettle();
      expect(find.text('Categories page'), findsOneWidget);
    });

    testWidgets('the cart chip on the provider page opens the cart',
        (tester) async {
      setViewport(tester, width: 800);
      final container = makeContainer();
      container
          .read(cartProvider.notifier)
          .addOffering(acWash, providerName: providerA.displayName);

      await tester.pumpWidget(
        buildApp(container, initialRoute: '/providers/prov-a'),
      );
      await tester.pumpAndSettle();

      final chip = find.byKey(const Key('provider_detail_cart_badge'));
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
      expect(find.bySemanticsLabel('Open cart, 1 service'), findsOneWidget);

      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text('Review your cart'), findsOneWidget);
      expect(textOf(tester, 'cart_total_value'), r'$25.00');
    });

    for (final locale in const [Locale('en'), Locale('km')]) {
      for (final width in const [320.0, 360.0]) {
        for (final scale in const [1.0, 1.3]) {
          testWidgets(
              'cart lays out in ${locale.languageCode} at ${width}dp and $scale scale',
              (tester) async {
            setViewport(tester, width: width);
            final container = makeContainer();
            final cart = container.read(cartProvider.notifier);
            cart.addOffering(acWash, providerName: providerA.displayName);
            cart.addOffering(gasTopUp, providerName: providerA.displayName);

            await tester.pumpWidget(buildApp(
              container,
              locale: locale,
              textScale: scale,
            ));
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
            expect(textOf(tester, 'cart_total_value'), r'$60.50');
            if (locale.languageCode == 'km') {
              expect(find.text('សរុប'), findsOneWidget);
            }
          });
        }
      }
    }
  });
}
