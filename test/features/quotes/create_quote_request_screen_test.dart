import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/services/photo_source.dart';
import 'package:service_pilot/features/cart/providers/cart_provider.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/screens/provider_detail_screen.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/quotes/models/quote_request_input.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/features/quotes/providers/quote_provider.dart';
import 'package:service_pilot/features/quotes/screens/create_quote_request_screen.dart';
import 'package:service_pilot/features/quotes/screens/quote_request_confirmation_screen.dart';
import 'package:service_pilot/features/quotes/screens/quote_request_detail_screen.dart';
import 'package:service_pilot/features/quotes/services/quote_service.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

const _homeowner = UserModel(
  id: 'customer-1',
  fullName: 'Sophea Meas',
  email: 'sophea@example.test',
  phoneNumber: '+85512345678',
  role: AppRole.homeowner,
  status: 'active',
);

const _provider = ProviderModel(
  id: 'prov-dara-ac',
  name: 'Dara Chhum',
  type: ProviderType.independent,
  specialties: ['Inverter AC Diagnostics'],
  categoryIds: ['cat-ac'],
  coverageAreas: ['Toul Kork'],
  isAvailable: true,
  status: 'active',
);

const _unavailableProvider = ProviderModel(
  id: 'prov-busy',
  name: 'Busy Provider',
  type: ProviderType.independent,
  coverageAreas: ['Sen Sok'],
  isAvailable: false,
  unavailableReason: 'Fully booked today',
  status: 'active',
);

const _quoteOffering = OfferingModel(
  id: 'offering-dara-pcb-quote',
  providerId: 'prov-dara-ac',
  providerName: 'Dara Chhum',
  categoryId: 'cat-ac',
  categoryName: 'Air Conditioner Repair & Care',
  title: 'Inverter Mainboard & PCB Replacement',
  description: 'Requires on-site diagnostics and custom quote.',
  pricingMode: OfferingPricingMode.quoteRequired,
  price: null,
  isActive: true,
);

const _fixedOffering = OfferingModel(
  id: 'offering-dara-wash',
  providerId: 'prov-dara-ac',
  providerName: 'Dara Chhum',
  categoryId: 'cat-ac',
  categoryName: 'Air Conditioner Repair & Care',
  title: 'Split Coil Deep Wash',
  description: 'Standard coil wash and drain cleaning.',
  pricingMode: OfferingPricingMode.fixed,
  price: 25.0,
  unit: 'unit',
  isActive: true,
);

/// 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _FakePhotoSource implements IPhotoSource {
  _FakePhotoSource({this.size});

  final int? size;
  final requestedLimits = <int>[];

  @override
  Future<List<BookingPhoto>> pick(PhotoOrigin origin, {required int limit}) async {
    requestedLimits.add(limit);
    return [
      for (var i = 0; i < 2 && i < limit; i++)
        BookingPhoto(
          bytes: size == null ? _png : Uint8List(size!),
          name: 'quote_photo_$i.png',
          contentType: 'image/png',
        ),
    ];
  }
}

class _FailingQuoteService extends InMemoryQuoteService {
  @override
  Future<QuoteRequestModel> createQuoteRequest(QuoteRequestInput request) {
    throw const QuoteSubmissionException('Network error');
  }
}

void main() {
  late InMemoryQuoteService quoteService;
  late _FakePhotoSource photoSource;

  setUp(() {
    quoteService = InMemoryQuoteService();
    photoSource = _FakePhotoSource();
  });

  Widget buildApp({
    String initialLocation =
        '/providers/prov-dara-ac/quote?offeringId=offering-dara-pcb-quote',
    IQuoteService? customQuoteService,
    IPhotoSource? customPhotoSource,
    List<ProviderModel> providers = const [_provider, _unavailableProvider],
    List<OfferingModel> offerings = const [_quoteOffering, _fixedOffering],
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    ProviderContainer? container,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/providers/:providerId',
          builder: (_, state) => ProviderDetailScreen(
            providerId: state.pathParameters['providerId']!,
          ),
        ),
        GoRoute(
          path: '/providers/:providerId/quote',
          builder: (_, state) {
            final extra = state.extra;
            final args = extra is QuoteRequestRouteArgs ? extra : null;
            return CreateQuoteRequestScreen(
              providerId: state.pathParameters['providerId']!,
              offeringId: state.uri.queryParameters['offeringId'] ?? '',
              initialProvider: args?.provider,
              initialOffering: args?.offering,
            );
          },
        ),
        GoRoute(
          path: '/quotes/:quoteId/sent',
          builder: (_, state) => QuoteRequestConfirmationScreen(
            quoteId: state.pathParameters['quoteId']!,
            quote: state.extra as QuoteRequestModel?,
          ),
        ),
        GoRoute(
          path: '/quotes/:quoteId',
          builder: (_, state) => QuoteRequestDetailScreen(
            quoteId: state.pathParameters['quoteId']!,
            initialQuote: state.extra as QuoteRequestModel?,
          ),
        ),
        GoRoute(
          path: '/home/customer',
          builder: (_, __) => const Scaffold(body: Text('customer home')),
        ),
      ],
    );

    final child = MaterialApp.router(
      routerConfig: router,
      locale: locale,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: widget!,
      ),
    );

    if (container != null) {
      return UncontrolledProviderScope(container: container, child: child);
    }

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_homeowner),
        activeCustomerIdProvider.overrideWithValue(_homeowner.id),
        quoteServiceProvider.overrideWithValue(
          customQuoteService ?? quoteService,
        ),
        providerServiceProvider.overrideWithValue(
          ProviderService(initialProviders: providers),
        ),
        offeringServiceProvider.overrideWithValue(
          OfferingService(initialOfferings: offerings),
        ),
        photoSourceProvider.overrideWithValue(
          customPhotoSource ?? photoSource,
        ),
      ],
      child: child,
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  void setViewport(WidgetTester tester, double width, double height) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('SCRUM-83 / QUOTE-1: Separate Quote Request Flow', () {
    testWidgets(
        'SCRUM-134: shows selected quote-required offering and validates description',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Describe the job'), findsOneWidget);
      expect(
        find.byKey(const Key('quote_selected_offering_offering-dara-pcb-quote')),
        findsOneWidget,
      );
      expect(
        find.text('Inverter Mainboard & PCB Replacement'),
        findsWidgets,
      );
      expect(find.text('Quote Required'), findsOneWidget);

      // No booking-only fields (address/date/time) appear on the quote form.
      expect(find.byKey(const Key('booking_address_field')), findsNothing);
      expect(find.byKey(const Key('booking_datetime_field')), findsNothing);

      // Submitting empty description shows required validation error.
      await tapVisible(tester, find.byKey(const Key('quote_submit_button')));
      expect(
        find.text('Describe the problem so the provider knows what to expect.'),
        findsOneWidget,
      );

      // Too-short description shows minimum length error.
      await tester.enterText(
        find.byKey(const Key('quote_description_field')),
        'Broken AC',
      );
      await tapVisible(tester, find.byKey(const Key('quote_submit_button')));
      expect(
        find.text('Add a little more detail (at least 15 characters).'),
        findsOneWidget,
      );
      expect(await quoteService.getCustomerQuoteRequests('customer-1'), isEmpty);
    });

    testWidgets(
        'SCRUM-135 & SCRUM-136: sends description + photo, saves Requested for offering & provider, shows feedback, and keeps cart separate',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(_homeowner),
          activeCustomerIdProvider.overrideWithValue(_homeowner.id),
          quoteServiceProvider.overrideWithValue(quoteService),
          providerServiceProvider.overrideWithValue(
            ProviderService(initialProviders: const [_provider]),
          ),
          offeringServiceProvider.overrideWithValue(
            OfferingService(initialOfferings: const [_quoteOffering, _fixedOffering]),
          ),
          photoSourceProvider.overrideWithValue(photoSource),
        ],
      );
      addTearDown(container.dispose);

      // Pre-populate the cart with a fixed-price offering.
      final addResult =
          container.read(cartProvider.notifier).addOffering(_fixedOffering);
      expect(addResult.accepted, isTrue);
      expect(container.read(cartProvider).itemCount, 1);

      await tester.pumpWidget(
        buildApp(
          initialLocation: '/providers/prov-dara-ac',
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Request a Quote" from ProviderDetailScreen.
      await tapVisible(
        tester,
        find.byKey(const Key('btn_quote_offering-dara-pcb-quote')),
      );
      expect(find.text('Request a quote'), findsOneWidget);

      // Attach two photos via gallery, then remove one.
      await tapVisible(tester, find.byKey(const Key('quote_add_photo')));
      await tester.tap(find.byKey(const Key('quote_photo_gallery')));
      await tester.pumpAndSettle();
      expect(photoSource.requestedLimits, [5]);
      expect(find.byKey(const Key('quote_photo_0')), findsOneWidget);
      expect(find.byKey(const Key('quote_photo_1')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('quote_photo_remove_0')));
      expect(find.byKey(const Key('quote_photo_1')), findsNothing);

      // Enter valid description and submit.
      await tester.enterText(
        find.byKey(const Key('quote_description_field')),
        'Outdoor inverter board clicks and shows E5 error after surge.',
      );
      await tapVisible(tester, find.byKey(const Key('quote_submit_button')));

      // Stored for customer and provider in Requested status.
      final customerQuotes =
          await quoteService.getCustomerQuoteRequests('customer-1');
      final providerQuotes =
          await quoteService.getProviderQuoteRequests('prov-dara-ac');
      expect(customerQuotes, hasLength(1));
      expect(providerQuotes, hasLength(1));

      final saved = customerQuotes.single;
      expect(saved.status, QuoteStatus.requested);
      expect(saved.providerId, 'prov-dara-ac');
      expect(saved.offeringId, 'offering-dara-pcb-quote');
      expect(saved.offeringTitle, 'Inverter Mainboard & PCB Replacement');
      expect(
        saved.description,
        'Outdoor inverter board clicks and shows E5 error after surge.',
      );
      expect(saved.photoUrls, hasLength(1));
      expect(saved.quotedPrice, isNull);

      // Cart remains untouched.
      expect(container.read(cartProvider).itemCount, 1);
      expect(container.read(cartProvider).totalPrice, 25.0);
      expect(
        container.read(cartProvider).items.single.offering.id,
        'offering-dara-wash',
      );

      // Confirmation feedback screen.
      expect(find.byKey(const Key('quote_request_sent_hero')), findsOneWidget);
      expect(find.text('Quote request sent'), findsOneWidget);
      expect(
        find.byKey(const Key('quote_confirmation_status_badge')),
        findsOneWidget,
      );
      expect(find.text('Requested'), findsWidgets);
      expect(find.text('1 photo attached'), findsOneWidget);

      // Navigating to View quote request shows the live detail state.
      await tapVisible(
        tester,
        find.byKey(const Key('quote_view_status_button')),
      );
      expect(find.byKey(const Key('quote_detail_status_badge')), findsOneWidget);
      expect(
        find.text('Inverter Mainboard & PCB Replacement'),
        findsWidgets,
      );
    });

    testWidgets('rejects non-quote offerings and unavailable providers',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          initialLocation:
              '/providers/prov-dara-ac/quote?offeringId=offering-dara-wash',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quote_offering_ineligible')), findsOneWidget);
      expect(find.byKey(const Key('quote_submit_button')), findsNothing);

      await tester.pumpWidget(
        buildApp(
          initialLocation:
              '/providers/prov-busy/quote?offeringId=offering-dara-pcb-quote',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quote_provider_unavailable')), findsOneWidget);
      expect(find.byKey(const Key('quote_submit_button')), findsNothing);
    });

    testWidgets('save failure shows error snackbar and keeps entered details',
        (tester) async {
      await tester.pumpWidget(
        buildApp(customQuoteService: _FailingQuoteService()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('quote_description_field')),
        'Outdoor unit breaker trips immediately on startup.',
      );
      await tapVisible(tester, find.byKey(const Key('quote_submit_button')));

      expect(
        find.text(
          "We couldn't send your quote request. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      expect(
        find.text('Outdoor unit breaker trips immediately on startup.'),
        findsOneWidget,
      );
    });

    testWidgets('photos over 5 MB are refused with a clear message',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          customPhotoSource: _FakePhotoSource(
            size: BookingRequestValidator.maxPhotoBytes + 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('quote_add_photo')));
      await tester.tap(find.byKey(const Key('quote_photo_camera')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Each photo must be 5 MB or smaller. Choose a smaller photo.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('quote_photo_0')), findsNothing);
    });

    for (final (locale, width) in [
      (const Locale('en'), 320.0),
      (const Locale('en'), 360.0),
      (const Locale('km'), 320.0),
      (const Locale('km'), 360.0),
    ]) {
      testWidgets(
          'renders cleanly in ${locale.languageCode} at ${width.toInt()}dp with 130% text scale',
          (tester) async {
        setViewport(tester, width, 900);
        await tester.pumpWidget(buildApp(locale: locale, textScale: 1.3));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('quote_description_field')), findsOneWidget);
        expect(find.byKey(const Key('quote_add_photo')), findsOneWidget);
        expect(find.byKey(const Key('quote_submit_button')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
