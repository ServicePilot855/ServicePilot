import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
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
  String id = 'q-1',
  QuoteStatus status = QuoteStatus.requested,
  double? quotedPrice,
  double? approvedPrice,
  String? bookingId,
}) {
  return QuoteRequestModel(
    id: id,
    customerId: 'customer-1',
    customerName: 'Sophea Meas',
    providerId: 'prov-ind-1',
    providerName: 'Dara Chhum',
    offeringId: 'off-quote-1',
    offeringTitle: 'Central Inverter PCB Diagnosis',
    description: 'Inverter board clicks repeatedly and blinks E5.',
    status: status,
    quotedPrice: quotedPrice,
    approvedPrice: approvedPrice,
    bookingId: bookingId,
    createdAt: DateTime(2026, 11, 27, 9),
  );
}

const _homeowner = UserModel(
  id: 'customer-1',
  fullName: 'Sophea Meas',
  email: 'sophea@example.test',
  phoneNumber: '+85512000111',
  role: AppRole.homeowner,
  status: 'active',
);

const _provider = UserModel(
  id: 'prov-ind-1',
  fullName: 'Dara Chhum',
  email: 'dara@example.test',
  phoneNumber: '+85512345678',
  role: AppRole.independentProvider,
  status: 'active',
);

void main() {
  late InMemoryQuoteService quotes;
  late BookingService bookings;

  Future<void> pumpApp(
    WidgetTester tester, {
    required String path,
    required UserModel user,
    required List<QuoteRequestModel> initialQuotes,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    double width = 360,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    quotes = InMemoryQuoteService(initialQuotes: initialQuotes);
    bookings = BookingService(
      initialBookings: const [],
      customerId: _homeowner.id,
      findQuote: quotes.getQuoteRequestById,
      onQuoteBooked: quotes.linkBooking,
    );
    final fakeFirestore = FakeFirebaseFirestore();

    final container = ProviderContainer(overrides: [
      authProvider.overrideWith(() => _SignedIn(user)),
      quoteServiceProvider.overrideWithValue(quotes),
      bookingServiceProvider.overrideWithValue(bookings),
      offeringServiceProvider.overrideWithValue(OfferingService()),
      companyProfileServiceProvider.overrideWithValue(
        CompanyProfileService(firestore: fakeFirestore),
      ),
      independentProfileServiceProvider.overrideWithValue(
        IndependentProfileService(firestore: fakeFirestore),
      ),
    ]);

    final router = container.read(appRouterProvider);
    addTearDown(bookings.dispose);
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

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('QUOTE-3 / SCRUM-85: provider sends a price', () {
    testWidgets('a valid price moves the request to Quoted', (tester) async {
      await pumpApp(
        tester,
        path: '/provider/quotes/q-1',
        user: _provider,
        initialQuotes: [_quote()],
      );

      expect(find.byKey(const Key('provider_quote_price_field')), findsOne);
      await tapVisible(
          tester, find.byKey(const Key('provider_quote_send_price_button')));
      expect(find.text('Enter the price for this job.'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('provider_quote_price_field')), '12.345');
      await tapVisible(
          tester, find.byKey(const Key('provider_quote_send_price_button')));
      expect(
        find.text(
            'Enter an amount greater than zero with up to two decimal places.'),
        findsOneWidget,
      );
      expect((await quotes.getQuoteRequestById('q-1'))!.status,
          QuoteStatus.requested);

      await tester.enterText(
          find.byKey(const Key('provider_quote_price_field')), '85');
      await tapVisible(
          tester, find.byKey(const Key('provider_quote_send_price_button')));

      final saved = await quotes.getQuoteRequestById('q-1');
      expect(saved!.status, QuoteStatus.quoted);
      expect(saved.quotedPrice, 85);
      expect(find.byKey(const Key('provider_quote_price_field')), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('provider_quote_detail_price')))
            .data,
        r'$85.00',
      );
      expect(
          find.text('Waiting for the homeowner to review your quoted price.'),
          findsOneWidget);
    });

    testWidgets('a priced request shows no price form', (tester) async {
      await pumpApp(
        tester,
        path: '/provider/quotes/q-1',
        user: _provider,
        initialQuotes: [_quote(status: QuoteStatus.quoted, quotedPrice: 40)],
      );

      expect(find.byKey(const Key('provider_quote_price_field')), findsNothing);
      expect(find.byKey(const Key('provider_quote_send_price_button')),
          findsNothing);
    });

    testWidgets('another provider cannot open the request', (tester) async {
      await pumpApp(
        tester,
        path: '/provider/quotes/q-1',
        user: _provider.copyWith(id: 'prov-other', email: 'other@example.test'),
        initialQuotes: [_quote()],
      );

      expect(find.byKey(const Key('provider_quote_inaccessible_notice')),
          findsOneWidget);
      expect(find.byKey(const Key('provider_quote_price_field')), findsNothing);
    });

    testWidgets('fits a 320dp phone in Khmer at 130% text', (tester) async {
      await pumpApp(
        tester,
        path: '/provider/quotes/q-1',
        user: _provider,
        initialQuotes: [_quote()],
        locale: const Locale('km'),
        textScale: 1.3,
        width: 320,
      );

      expect(find.byKey(const Key('provider_quote_price_field')), findsOne);
      expect(tester.takeException(), isNull);
    });
  });

  group('QUOTE-4 / SCRUM-86: homeowner approves the price', () {
    testWidgets('shows the price and records the approval', (tester) async {
      await pumpApp(
        tester,
        path: '/quotes/q-1',
        user: _homeowner,
        initialQuotes: [_quote(status: QuoteStatus.quoted, quotedPrice: 85)],
      );

      expect(
        tester
            .widget<Text>(find.byKey(const Key('quote_detail_quoted_price')))
            .data,
        r'$85.00',
      );
      expect(find.text(r'Dara Chhum quoted $85.00. Approve it to book a time.'),
          findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('quote_approve_button')));

      final saved = await quotes.getQuoteRequestById('q-1');
      expect(saved!.status, QuoteStatus.approved);
      expect(saved.approvedPrice, 85);
      expect(find.byKey(const Key('quote_approve_button')), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('quote_detail_approved_price')))
            .data,
        r'$85.00',
      );
      expect(find.byKey(const Key('quote_book_button')), findsOneWidget);
    });

    testWidgets('a requested quote has nothing to approve', (tester) async {
      await pumpApp(
        tester,
        path: '/quotes/q-1',
        user: _homeowner,
        initialQuotes: [_quote()],
      );

      expect(find.byKey(const Key('quote_approve_button')), findsNothing);
      expect(find.byKey(const Key('quote_book_button')), findsNothing);
    });

    testWidgets('another account sees no approve or book action',
        (tester) async {
      await pumpApp(
        tester,
        path: '/quotes/q-1',
        user: _homeowner.copyWith(id: 'customer-2'),
        initialQuotes: [_quote(status: QuoteStatus.quoted, quotedPrice: 85)],
      );

      expect(find.byKey(const Key('quote_approve_button')), findsNothing);
      expect(find.byKey(const Key('quote_book_button')), findsNothing);
    });
  });

  group('QUOTE-5 / SCRUM-87: book a time with the approved quote', () {
    final approved = _quote(
        status: QuoteStatus.approved, quotedPrice: 85, approvedPrice: 85);

    testWidgets('creates a Pending booking that keeps the approved price', (
      tester,
    ) async {
      await pumpApp(
        tester,
        path: '/quotes/q-1',
        user: _homeowner,
        initialQuotes: [approved],
      );
      await tapVisible(tester, find.byKey(const Key('quote_book_button')));

      expect(
        tester
            .widget<Text>(find.byKey(const Key('quote_booking_approved_price')))
            .data,
        r'$85.00',
      );

      await tester.enterText(
        find.byKey(const Key('quote_booking_address_field')),
        'House 12, Street 271, Toul Kork, Phnom Penh',
      );
      await tapVisible(tester, find.byKey(const Key('booking_date_picker')));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('booking_time_picker')));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapVisible(
          tester, find.byKey(const Key('quote_booking_submit_button')));

      final saved = await bookings.getCustomerBookings(_homeowner.id);
      expect(saved, hasLength(1));
      expect(saved.single.status, BookingStatus.pending);
      expect(saved.single.totalPrice, 85);
      expect(saved.single.quoteId, 'q-1');
      expect(saved.single.providerId, 'prov-ind-1');
      expect((await quotes.getQuoteRequestById('q-1'))!.bookingId,
          saved.single.id);
      expect(
          find.byKey(const Key('quote_booking_submit_button')), findsNothing);
    });

    testWidgets('an empty form saves nothing', (tester) async {
      await pumpApp(
        tester,
        path: '/quotes/q-1/book',
        user: _homeowner,
        initialQuotes: [approved],
      );

      await tapVisible(
          tester, find.byKey(const Key('quote_booking_submit_button')));

      expect(await bookings.getCustomerBookings(_homeowner.id), isEmpty);
      expect(find.byKey(const Key('quote_booking_submit_button')), findsOne);
    });

    testWidgets('an unapproved quote cannot enter the booking flow', (
      tester,
    ) async {
      await pumpApp(
        tester,
        path: '/quotes/q-1/book',
        user: _homeowner,
        initialQuotes: [_quote(status: QuoteStatus.quoted, quotedPrice: 85)],
      );

      expect(find.byKey(const Key('quote_booking_blocked')), findsOneWidget);
      expect(find.text('Approve the quoted price before you book a time.'),
          findsOneWidget);
      expect(
          find.byKey(const Key('quote_booking_submit_button')), findsNothing);
    });

    testWidgets('another homeowner cannot book the quote', (tester) async {
      await pumpApp(
        tester,
        path: '/quotes/q-1/book',
        user: _homeowner.copyWith(id: 'customer-2'),
        initialQuotes: [approved],
      );

      expect(find.text("This quote can't be booked from your account."),
          findsOneWidget);
      expect(
          find.byKey(const Key('quote_booking_submit_button')), findsNothing);
    });

    testWidgets('a booked quote links to its booking', (tester) async {
      await pumpApp(
        tester,
        path: '/quotes/q-1/book',
        user: _homeowner,
        initialQuotes: [
          approved.copyWith(bookingId: 'bk-1'),
        ],
      );

      expect(find.text('You already booked a time for this quote.'),
          findsOneWidget);
      expect(
          find.byKey(const Key('quote_booking_view_booking')), findsOneWidget);
    });

    testWidgets('fits a 320dp phone in Khmer at 130% text', (tester) async {
      await pumpApp(
        tester,
        path: '/quotes/q-1/book',
        user: _homeowner,
        initialQuotes: [approved],
        locale: const Locale('km'),
        textScale: 1.3,
        width: 320,
      );

      expect(find.byKey(const Key('quote_booking_submit_button')), findsOne);
      expect(tester.takeException(), isNull);
    });
  });
}
