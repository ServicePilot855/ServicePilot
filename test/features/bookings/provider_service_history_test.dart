import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/router/app_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/incoming_booking_request.dart';
import 'package:service_pilot/features/bookings/models/provider_service_record.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/screens/provider_booking_detail_screen.dart';
import 'package:service_pilot/features/bookings/screens/provider_service_history_screen.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/services/firestore_booking_service.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/providers/quote_provider.dart';
import 'package:service_pilot/features/quotes/services/quote_service.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';
import 'package:service_pilot/shared/home/company_home.dart';
import 'package:service_pilot/shared/home/customer_home.dart';
import 'package:service_pilot/shared/home/technician_home.dart';

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(this._user);
  final UserModel _user;

  @override
  AuthState build() => AuthStateAuthenticated(_user);
}

class _FailingHistoryBookingService extends BookingService {
  @override
  Future<List<ProviderServiceRecord>> getProviderServiceRecords(
    String providerId,
  ) {
    return Future.error(Exception('server unavailable'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const independentUser = UserModel(
    id: 'prov-virak-ac',
    fullName: 'Virak Chan',
    email: 'virak@example.test',
    phoneNumber: '+85512345678',
    role: AppRole.independentProvider,
    status: 'active',
  );

  const companyUser = UserModel(
    id: 'prov-fixco-company',
    fullName: 'FixCo Admin',
    email: 'admin@fixco.test',
    phoneNumber: '+85512999888',
    role: AppRole.company,
    status: 'active',
    companyId: 'prov-fixco-company',
    companyName: 'Phnom Penh Fix Co.',
  );

  const outsiderProvider = UserModel(
    id: 'prov-outsider',
    fullName: 'Outsider Provider',
    email: 'outsider@example.test',
    phoneNumber: '+85511000111',
    role: AppRole.independentProvider,
    status: 'active',
  );

  const homeownerUser = UserModel(
    id: 'customer-1',
    fullName: 'Sokha Homeowner',
    email: 'customer@example.test',
    phoneNumber: '+85599887766',
    role: AppRole.homeowner,
    status: 'active',
  );

  final baseTime = DateTime(2026, 11, 20, 9, 0);

  BookingModel makeBooking({
    required String id,
    required String providerId,
    required String serviceTitle,
    required BookingStatus status,
    required DateTime appointmentAt,
    String? technicianName,
  }) {
    return BookingModel(
      id: id,
      customerId: homeownerUser.id,
      providerId: providerId,
      providerName: providerId == companyUser.id
          ? 'Phnom Penh Fix Co.'
          : 'Virak Chan',
      serviceCategory: 'Air Conditioner Repair & Care',
      serviceTitle: serviceTitle,
      description: 'Service record summary for $serviceTitle.',
      address: 'St. 310, BKK1, Phnom Penh',
      preferredDateTime: appointmentAt,
      confirmedAppointmentAt:
          status == BookingStatus.completed ? appointmentAt : null,
      status: status,
      totalPrice: 35.0,
      assignedTechnicianName: technicianName,
      createdAt: baseTime,
    );
  }

  final fixtures = [
    makeBooking(
      id: 'bk-indep-completed',
      providerId: independentUser.id,
      serviceTitle: 'AC Deep Chemical Wash',
      status: BookingStatus.completed,
      appointmentAt: DateTime(2026, 11, 25, 10, 0),
    ),
    makeBooking(
      id: 'bk-indep-cancelled',
      providerId: independentUser.id,
      serviceTitle: 'Gas Top-up Request',
      status: BookingStatus.cancelled,
      appointmentAt: DateTime(2026, 11, 24, 15, 30),
    ),
    makeBooking(
      id: 'bk-indep-declined',
      providerId: independentUser.id,
      serviceTitle: 'Night Emergency Fan Fix',
      status: BookingStatus.declined,
      appointmentAt: DateTime(2026, 11, 23, 21, 0),
    ),
    makeBooking(
      id: 'bk-indep-active',
      providerId: independentUser.id,
      serviceTitle: 'Active Confirmed Job Must Hide',
      status: BookingStatus.confirmed,
      appointmentAt: DateTime(2026, 11, 29, 10, 0),
    ),
    makeBooking(
      id: 'bk-comp-completed',
      providerId: companyUser.id,
      serviceTitle: 'Commercial Chiller Overhaul',
      status: BookingStatus.completed,
      appointmentAt: DateTime(2026, 11, 26, 9, 0),
      technicianName: 'Sokha Vann',
    ),
    makeBooking(
      id: 'bk-comp-cancelled',
      providerId: companyUser.id,
      serviceTitle: 'Pipe Pressure Valve Fix',
      status: BookingStatus.cancelled,
      appointmentAt: DateTime(2026, 11, 22, 11, 0),
    ),
    makeBooking(
      id: 'bk-comp-declined',
      providerId: companyUser.id,
      serviceTitle: 'Out-of-Area Wiring Job',
      status: BookingStatus.declined,
      appointmentAt: DateTime(2026, 11, 21, 14, 0),
    ),
  ];

  void setViewport(WidgetTester tester, double width, double height) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget wrapHistoryApp({
    required UserModel user,
    required IBookingService bookingService,
    Widget? home,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => home ?? const ProviderServiceHistoryScreen(),
        ),
        GoRoute(
          path: ProviderServiceHistoryScreen.path,
          builder: (_, __) => const ProviderServiceHistoryScreen(),
        ),
        GoRoute(
          path: '/provider/bookings/:bookingId',
          builder: (_, state) => ProviderBookingDetailScreen(
            bookingId: state.pathParameters['bookingId']!,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('login')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier(user)),
        bookingServiceProvider.overrideWithValue(bookingService),
        quoteServiceProvider.overrideWithValue(
          InMemoryQuoteService(initialQuotes: const <QuoteRequestModel>[]),
        ),
        providerServiceProvider.overrideWithValue(
          ProviderService(initialProviders: const [
            ProviderModel(
              id: 'prov-virak-ac',
              name: 'Virak Chan',
              type: ProviderType.independent,
              status: 'active',
            ),
            ProviderModel(
              id: 'prov-fixco-company',
              name: 'Phnom Penh Fix Co.',
              type: ProviderType.company,
              businessName: 'Phnom Penh Fix Co.',
              status: 'active',
            ),
          ]),
        ),
        offeringServiceProvider.overrideWithValue(
          OfferingService(initialOfferings: const []),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
    );
  }

  group('SCRUM-90 / SCRUM-153 / SCRUM-154: Service records domain & services',
      () {
    test('BookingStatus.isClosedRecord matches only completed/cancelled/declined',
        () {
      expect(BookingStatus.completed.isClosedRecord, isTrue);
      expect(BookingStatus.cancelled.isClosedRecord, isTrue);
      expect(BookingStatus.declined.isClosedRecord, isTrue);

      expect(BookingStatus.pending.isClosedRecord, isFalse);
      expect(BookingStatus.confirmed.isClosedRecord, isFalse);
      expect(BookingStatus.assigned.isClosedRecord, isFalse);
      expect(BookingStatus.inProgress.isClosedRecord, isFalse);
    });

    test('In-memory BookingService returns only owned closed service records',
        () async {
      final service = BookingService(initialBookings: fixtures);
      addTearDown(service.dispose);

      final indep = await service.getProviderServiceRecords(independentUser.id);
      expect(
        indep.map((r) => (r.id, r.status)),
        [
          ('bk-indep-completed', BookingStatus.completed),
          ('bk-indep-cancelled', BookingStatus.cancelled),
          ('bk-indep-declined', BookingStatus.declined),
        ],
      );

      final comp = await service.getProviderServiceRecords(companyUser.id);
      expect(
        comp.map((r) => (r.id, r.status)),
        [
          ('bk-comp-completed', BookingStatus.completed),
          ('bk-comp-cancelled', BookingStatus.cancelled),
          ('bk-comp-declined', BookingStatus.declined),
        ],
      );

      expect(
        await service.getProviderServiceRecords(outsiderProvider.id),
        isEmpty,
      );
    });

    test(
        'FirestoreBookingService aggregates Completed, Cancelled archive, and Declined archive records and archives cancellations',
        () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreBookingService(firestore: firestore);

      // Seed Completed booking + Declined preview + Pending booking to cancel.
      final completed = fixtures.first;
      await firestore
          .collection('bookings')
          .doc(completed.id)
          .set(completed.toFirestore());

      final declinedPreview = IncomingBookingRequest(
        id: 'bk-indep-declined',
        serviceTitle: 'Night Emergency Fan Fix',
        description: 'Outside service hours.',
        appointmentDate: DateTime(2026, 11, 23, 21, 0),
      );
      await firestore
          .collection('providers')
          .doc(independentUser.id)
          .collection('declinedBookingRequests')
          .doc(declinedPreview.id)
          .set(declinedPreview.toFirestore());

      final pendingToCancel = makeBooking(
        id: 'bk-indep-to-cancel',
        providerId: independentUser.id,
        serviceTitle: 'Filter Cleaning Visit',
        status: BookingStatus.pending,
        appointmentAt: DateTime(2026, 11, 24, 15, 30),
      );
      await firestore
          .collection('bookings')
          .doc(pendingToCancel.id)
          .set(pendingToCancel.toFirestore());
      await firestore
          .collection('providers')
          .doc(independentUser.id)
          .collection('incomingBookingRequests')
          .doc(pendingToCancel.id)
          .set(IncomingBookingRequest.fromBooking(pendingToCancel).toFirestore());

      // Seed another provider's completed booking that must stay isolated.
      final otherCompleted = fixtures[4];
      await firestore
          .collection('bookings')
          .doc(otherCompleted.id)
          .set(otherCompleted.toFirestore());

      await service.cancelBooking(
        bookingId: pendingToCancel.id,
        customerId: homeownerUser.id,
        reason: 'Rescheduling',
      );

      final inboxAfterCancel = await firestore
          .collection('providers')
          .doc(independentUser.id)
          .collection('incomingBookingRequests')
          .doc(pendingToCancel.id)
          .get();
      expect(inboxAfterCancel.exists, isFalse);

      final cancelledArchive = await firestore
          .collection('providers')
          .doc(independentUser.id)
          .collection('cancelledBookingRequests')
          .doc(pendingToCancel.id)
          .get();
      expect(cancelledArchive.exists, isTrue);

      final records =
          await service.getProviderServiceRecords(independentUser.id);
      expect(
        records.map((r) => (r.id, r.status)),
        [
          ('bk-indep-completed', BookingStatus.completed),
          ('bk-indep-to-cancel', BookingStatus.cancelled),
          ('bk-indep-declined', BookingStatus.declined),
        ],
      );
      expect(records.first.appointmentDate, isNotNull);
      expect(
        await service.getProviderServiceRecords(outsiderProvider.id),
        isEmpty,
      );
    });
  });

  group('SCRUM-90 / BOOK-5: Provider service history UI & isolation', () {
    testWidgets(
        'Independent provider opens history from dashboard and sees Completed, Cancelled, and Declined records',
        (tester) async {
      setViewport(tester, 800, 1600);
      final service = BookingService(initialBookings: fixtures);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        wrapHistoryApp(
          user: independentUser,
          bookingService: service,
          home: const TechnicianHome(),
        ),
      );
      await tester.pumpAndSettle();

      final historyBtn = find.byKey(const Key('provider_view_history_button'));
      expect(historyBtn, findsOneWidget);
      await tester.ensureVisible(historyBtn);
      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Service records'), findsOneWidget);
      expect(find.text('AC Deep Chemical Wash'), findsOneWidget);
      expect(find.text('Gas Top-up Request'), findsOneWidget);
      expect(find.text('Night Emergency Fan Fix'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Declined'), findsOneWidget);

      // Active & unrelated records do not appear.
      expect(find.text('Active Confirmed Job Must Hide'), findsNothing);
      expect(find.text('Commercial Chiller Overhaul'), findsNothing);

      final expectedDate = DateFormat.yMMMd('en').add_jm().format(
            DateTime(2026, 11, 25, 10, 0),
          );
      expect(find.text(expectedDate), findsOneWidget);

      // Tapping Completed opens ProviderBookingDetailScreen.
      await tester.tap(
        find.byKey(const Key('provider_history_card_bk-indep-completed')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProviderBookingDetailScreen), findsOneWidget);
      expect(find.text('AC Deep Chemical Wash'), findsOneWidget);
    });

    testWidgets('Company admin sees only own company closed service records',
        (tester) async {
      setViewport(tester, 800, 1600);
      final service = BookingService(initialBookings: fixtures);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        wrapHistoryApp(
          user: companyUser,
          bookingService: service,
          home: const CompanyHome(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('provider_view_history_button')),
      );
      await tester.tap(find.byKey(const Key('provider_view_history_button')));
      await tester.pumpAndSettle();

      expect(find.text('Commercial Chiller Overhaul'), findsOneWidget);
      expect(find.text('Pipe Pressure Valve Fix'), findsOneWidget);
      expect(find.text('Out-of-Area Wiring Job'), findsOneWidget);
      expect(find.text('Sokha Vann'), findsOneWidget);
      expect(find.text('AC Deep Chemical Wash'), findsNothing);
    });

    testWidgets('Empty history displays a clear empty notice', (tester) async {
      setViewport(tester, 400, 900);
      final service = BookingService(initialBookings: fixtures);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        wrapHistoryApp(
          user: outsiderProvider,
          bookingService: service,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('provider_history_empty_notice')),
        findsOneWidget,
      );
      expect(
        find.text(
          'You have no completed, cancelled, or declined service records yet.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Error state shows retry action', (tester) async {
      setViewport(tester, 400, 900);
      final service = _FailingHistoryBookingService();
      addTearDown(service.dispose);

      await tester.pumpWidget(
        wrapHistoryApp(
          user: independentUser,
          bookingService: service,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Unable to load service records right now. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('Homeowner cannot access /provider/bookings/history route',
        (tester) async {
      setViewport(tester, 600, 1000);
      final service = BookingService(initialBookings: fixtures);
      addTearDown(service.dispose);

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(homeownerUser)),
          bookingServiceProvider.overrideWithValue(service),
          quoteServiceProvider.overrideWithValue(
            InMemoryQuoteService(initialQuotes: const <QuoteRequestModel>[]),
          ),
        ],
      );
      final router = container.read(appRouterProvider);
      addTearDown(container.dispose);
      addTearDown(router.dispose);
      router.go(ProviderServiceHistoryScreen.path);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomerHome), findsOneWidget);
      expect(find.byType(ProviderServiceHistoryScreen), findsNothing);
    });

    for (final (locale, width) in [
      (const Locale('en'), 320.0),
      (const Locale('km'), 360.0),
    ]) {
      testWidgets(
          'renders service history cleanly in ${locale.languageCode} at ${width.toInt()}dp with 130% text scale',
          (tester) async {
        setViewport(tester, width, 1000);
        final service = BookingService(initialBookings: fixtures);
        addTearDown(service.dispose);

        await tester.pumpWidget(
          wrapHistoryApp(
            user: companyUser,
            bookingService: service,
            locale: locale,
            textScale: 1.3,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Commercial Chiller Overhaul'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
