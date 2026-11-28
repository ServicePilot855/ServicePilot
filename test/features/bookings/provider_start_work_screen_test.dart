import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/screens/booking_tracking_screen.dart';
import 'package:service_pilot/features/bookings/screens/provider_booking_detail_screen.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

class _MockAuthNotifier extends AuthNotifier {
  final UserModel _user;
  _MockAuthNotifier(this._user);

  @override
  AuthState build() => AuthStateAuthenticated(_user);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 28, 9, 0);
  final preferred = DateTime(2026, 11, 29, 14, 30);

  const providerUser = UserModel(
    id: 'prov-virak-ac',
    fullName: 'Virak Chan',
    email: 'technician@test.com',
    phoneNumber: '+85512345678',
    role: AppRole.independentProvider,
    status: 'active',
  );

  const customerUser = UserModel(
    id: 'customer-1',
    fullName: 'Sokha Homeowner',
    email: 'customer@test.com',
    phoneNumber: '+85599887766',
    role: AppRole.homeowner,
    status: 'active',
  );

  BookingModel booking({
    required String id,
    BookingStatus status = BookingStatus.confirmed,
    String? quoteId,
  }) {
    return BookingModel(
      id: id,
      customerId: customerUser.id,
      providerId: providerUser.id,
      providerName: 'Virak Chan',
      serviceCategory: 'Air Conditioner Repair & Care',
      serviceTitle: 'Split AC Chemical Wash',
      description: 'AC unit dripping water indoors.',
      address: 'St. 310, BKK1, Phnom Penh',
      preferredDateTime: preferred,
      status: status,
      totalPrice: 25.0,
      createdAt: now,
      quoteId: quoteId,
      confirmedAppointmentAt: preferred,
    );
  }

  void setupViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget providerApp(BookingService service, {required String bookingId}) {
    return ProviderScope(
      overrides: [
        bookingServiceProvider.overrideWithValue(service),
        authProvider.overrideWith(() => _MockAuthNotifier(providerUser)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProviderBookingDetailScreen(bookingId: bookingId),
      ),
    );
  }

  group('SCRUM-91 / WORK-1: provider start job UI', () {
    testWidgets(
      'provider starts a confirmed job; both views show In Progress',
      (tester) async {
        setupViewport(tester);
        final service = BookingService(
          initialBookings: [booking(id: 'bk-start-ui-1')],
          customerId: customerUser.id,
        );
        addTearDown(service.dispose);

        await tester.pumpWidget(providerApp(service, bookingId: 'bk-start-ui-1'));
        await tester.pumpAndSettle();

        final startButton =
            find.byKey(const Key('provider_start_booking_button'));
        await tester.scrollUntilVisible(
          startButton,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(startButton, findsOneWidget);

        await tester.tap(startButton);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('start_job_dialog')), findsOneWidget);

        await tester.tap(find.byKey(const Key('start_job_confirm_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('provider_booking_started_notice')),
          findsOneWidget,
        );
        expect(find.text('In Progress'), findsWidgets);
        expect(
          find.byKey(const Key('provider_start_booking_button')),
          findsNothing,
        );

        expect(
          (await service.getBookingById('bk-start-ui-1'))?.status,
          BookingStatus.inProgress,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bookingServiceProvider.overrideWithValue(service),
              authProvider.overrideWith(() => _MockAuthNotifier(customerUser)),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const BookingTrackingScreen(bookingId: 'bk-start-ui-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('In Progress'), findsWidgets);
      },
    );

    testWidgets('Not yet keeps the job confirmed', (tester) async {
      setupViewport(tester);
      final service = BookingService(
        initialBookings: [booking(id: 'bk-start-ui-2')],
        customerId: customerUser.id,
      );
      addTearDown(service.dispose);

      await tester.pumpWidget(providerApp(service, bookingId: 'bk-start-ui-2'));
      await tester.pumpAndSettle();

      final startButton = find.byKey(const Key('provider_start_booking_button'));
      await tester.scrollUntilVisible(
        startButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('start_job_keep_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('start_job_dialog')), findsNothing);
      expect(
        (await service.getBookingById('bk-start-ui-2'))?.status,
        BookingStatus.confirmed,
      );
    });

    testWidgets(
      'quote job without homeowner approval shows the quote error and stays confirmed',
      (tester) async {
        setupViewport(tester);
        final quote = QuoteRequestModel(
          id: 'q-ui',
          customerId: customerUser.id,
          providerId: providerUser.id,
          providerName: 'Virak Chan',
          offeringId: 'offer-1',
          offeringTitle: 'AC deep clean',
          description: 'Please quote two units.',
          status: QuoteStatus.quoted,
          quotedPrice: 45.0,
          createdAt: now,
        );
        final service = BookingService(
          initialBookings: [booking(id: 'bk-start-ui-3', quoteId: 'q-ui')],
          customerId: customerUser.id,
          findQuote: (id) async => id == 'q-ui' ? quote : null,
        );
        addTearDown(service.dispose);

        await tester.pumpWidget(providerApp(service, bookingId: 'bk-start-ui-3'));
        await tester.pumpAndSettle();

        final startButton =
            find.byKey(const Key('provider_start_booking_button'));
        await tester.scrollUntilVisible(
          startButton,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(startButton);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('start_job_confirm_button')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'The homeowner has not approved the quote for this job yet.',
          ),
          findsOneWidget,
        );
        expect(
          (await service.getBookingById('bk-start-ui-3'))?.status,
          BookingStatus.confirmed,
        );
      },
    );
  });
}
