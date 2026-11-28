import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/screens/provider_booking_detail_screen.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/services/firestore_booking_service.dart';
import 'package:service_pilot/features/bookings/widgets/provider_booking_list.dart';
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
import 'package:service_pilot/shared/home/technician_home.dart';

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(this._user);
  final UserModel _user;

  @override
  AuthState build() => AuthStateAuthenticated(_user);
}

class _FailingActiveBookingsService extends BookingService {
  @override
  Stream<List<BookingModel>> watchProviderActiveBookings(String providerId) {
    return Stream.error(Exception('network unavailable'));
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

  const unrelatedProviderUser = UserModel(
    id: 'prov-outsider',
    fullName: 'Outsider Tech',
    email: 'outsider@example.test',
    phoneNumber: '+85511000111',
    role: AppRole.independentProvider,
    status: 'active',
  );

  final baseTime = DateTime(2026, 11, 28, 9, 0);

  BookingModel makeBooking({
    required String id,
    required String providerId,
    required String serviceTitle,
    required BookingStatus status,
    required DateTime appointmentAt,
    String? technicianId,
    String? technicianName,
  }) {
    return BookingModel(
      id: id,
      customerId: 'customer-1',
      providerId: providerId,
      providerName: providerId == companyUser.id
          ? 'Phnom Penh Fix Co.'
          : 'Virak Chan',
      serviceCategory: 'Air Conditioner Repair & Care',
      serviceTitle: serviceTitle,
      description: 'Unit needs inspection and cleaning.',
      address: 'St. 310, BKK1, Phnom Penh',
      preferredDateTime: appointmentAt,
      confirmedAppointmentAt: appointmentAt,
      status: status,
      totalPrice: 30.0,
      assignedTechnicianId: technicianId,
      assignedTechnicianName: technicianName,
      createdAt: baseTime.subtract(const Duration(hours: 2)),
    );
  }

  final fixtures = [
    makeBooking(
      id: 'bk-indep-confirmed',
      providerId: independentUser.id,
      serviceTitle: 'Confirmed Split Wash',
      status: BookingStatus.confirmed,
      appointmentAt: DateTime(2026, 11, 29, 10, 0),
    ),
    makeBooking(
      id: 'bk-indep-inprogress',
      providerId: independentUser.id,
      serviceTitle: 'In-Progress Compressor Check',
      status: BookingStatus.inProgress,
      appointmentAt: DateTime(2026, 11, 28, 14, 0),
    ),
    makeBooking(
      id: 'bk-indep-pending',
      providerId: independentUser.id,
      serviceTitle: 'Pending Request Should Hide',
      status: BookingStatus.pending,
      appointmentAt: DateTime(2026, 11, 30, 9, 0),
    ),
    makeBooking(
      id: 'bk-indep-completed',
      providerId: independentUser.id,
      serviceTitle: 'Completed Past Job Should Hide',
      status: BookingStatus.completed,
      appointmentAt: DateTime(2026, 11, 27, 9, 0),
    ),
    makeBooking(
      id: 'bk-comp-assigned',
      providerId: companyUser.id,
      serviceTitle: 'Assigned Chiller Repair',
      status: BookingStatus.assigned,
      appointmentAt: DateTime(2026, 11, 29, 13, 30),
      technicianId: 'tech-sokha',
      technicianName: 'Sokha Vann',
    ),
    makeBooking(
      id: 'bk-comp-confirmed',
      providerId: companyUser.id,
      serviceTitle: 'Confirmed Pipe Leak Repair',
      status: BookingStatus.confirmed,
      appointmentAt: DateTime(2026, 11, 28, 16, 0),
    ),
    makeBooking(
      id: 'bk-comp-inprogress',
      providerId: companyUser.id,
      serviceTitle: 'In-Progress Wiring Fix',
      status: BookingStatus.inProgress,
      appointmentAt: DateTime(2026, 11, 28, 11, 0),
      technicianId: 'tech-dara',
      technicianName: 'Dara Meas',
    ),
    makeBooking(
      id: 'bk-comp-cancelled',
      providerId: companyUser.id,
      serviceTitle: 'Cancelled Job Should Hide',
      status: BookingStatus.cancelled,
      appointmentAt: DateTime(2026, 11, 28, 8, 0),
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

  Widget wrapDashboard({
    required UserModel user,
    required IBookingService bookingService,
    required Widget home,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
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

  group('SCRUM-89 / SCRUM-151 / SCRUM-152: Active work domain & services', () {
    test('BookingStatus.isActiveProviderWork matches only confirmed/assigned/inProgress',
        () {
      expect(BookingStatus.confirmed.isActiveProviderWork, isTrue);
      expect(BookingStatus.assigned.isActiveProviderWork, isTrue);
      expect(BookingStatus.inProgress.isActiveProviderWork, isTrue);

      expect(BookingStatus.pending.isActiveProviderWork, isFalse);
      expect(BookingStatus.completed.isActiveProviderWork, isFalse);
      expect(BookingStatus.cancelled.isActiveProviderWork, isFalse);
      expect(BookingStatus.declined.isActiveProviderWork, isFalse);
    });

    test('In-memory BookingService returns only owned active jobs', () async {
      final service = BookingService(initialBookings: fixtures);

      final indep = await service.getProviderActiveBookings(independentUser.id);
      expect(
        indep.map((b) => b.id).toSet(),
        {'bk-indep-confirmed', 'bk-indep-inprogress'},
      );

      final comp = await service.getProviderActiveBookings(companyUser.id);
      expect(
        comp.map((b) => b.id).toSet(),
        {'bk-comp-assigned', 'bk-comp-confirmed', 'bk-comp-inprogress'},
      );

      expect(
        await service.getProviderActiveBookings(unrelatedProviderUser.id),
        isEmpty,
      );
    });

    test('FirestoreBookingService queries active jobs with appointment & technician',
        () async {
      final firestore = FakeFirebaseFirestore();
      for (final b in fixtures) {
        await firestore.collection('bookings').doc(b.id).set(b.toFirestore());
      }
      final service = FirestoreBookingService(firestore: firestore);

      final comp = await service.getProviderActiveBookings(companyUser.id);
      expect(
        comp.map((b) => b.id).toSet(),
        {'bk-comp-assigned', 'bk-comp-confirmed', 'bk-comp-inprogress'},
      );
      final assigned = comp.firstWhere((b) => b.id == 'bk-comp-assigned');
      expect(assigned.assignedTechnicianName, 'Sokha Vann');
      expect(
        assigned.confirmedAppointmentAt,
        Timestamp.fromDate(DateTime(2026, 11, 29, 13, 30)).toDate(),
      );

      expect(
        await service.getProviderActiveBookings(unrelatedProviderUser.id),
        isEmpty,
      );
    });
  });

  group('SCRUM-89 / BOOK-4: Provider active work UI & isolation', () {
    testWidgets(
        'Independent provider sees only owned Confirmed & In Progress jobs sorted by appointment time',
        (tester) async {
      setViewport(tester, 800, 1600);
      final service = BookingService(initialBookings: fixtures);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        wrapDashboard(
          user: independentUser,
          bookingService: service,
          home: const TechnicianHome(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current appointments & jobs'), findsOneWidget);
      expect(find.text('Confirmed Split Wash'), findsOneWidget);
      expect(find.text('In-Progress Compressor Check'), findsOneWidget);
      expect(find.text('Pending Request Should Hide'), findsNothing);
      expect(find.text('Completed Past Job Should Hide'), findsNothing);
      expect(find.text('Assigned Chiller Repair'), findsNothing);

      // Earliest active appointment (Nov 28 14:00) appears above Nov 29 10:00.
      final inProgressTop = tester
          .getTopLeft(find.byKey(const Key('provider_booking_card_bk-indep-inprogress')))
          .dy;
      final confirmedTop = tester
          .getTopLeft(find.byKey(const Key('provider_booking_card_bk-indep-confirmed')))
          .dy;
      expect(inProgressTop, lessThan(confirmedTop));

      final expectedFormatted = DateFormat.yMMMd('en').add_jm().format(
            DateTime(2026, 11, 29, 10, 0),
          );
      expect(find.textContaining(expectedFormatted), findsOneWidget);
    });

    testWidgets(
        'Company admin sees active jobs, statuses, and assigned technician on list and detail screen',
        (tester) async {
      setViewport(tester, 800, 1800);
      final service = BookingService(initialBookings: fixtures);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        wrapDashboard(
          user: companyUser,
          bookingService: service,
          home: const CompanyHome(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assigned Chiller Repair'), findsOneWidget);
      expect(find.text('Confirmed Pipe Leak Repair'), findsOneWidget);
      expect(find.text('In-Progress Wiring Fix'), findsOneWidget);
      expect(find.text('Cancelled Job Should Hide'), findsNothing);
      expect(find.text('Confirmed Split Wash'), findsNothing);

      // Assigned technician shown when available, omitted when unassigned.
      expect(
        find.byKey(const Key('provider_booking_technician_bk-comp-assigned')),
        findsOneWidget,
      );
      expect(find.text('Assigned to Sokha Vann'), findsOneWidget);
      expect(find.text('Assigned to Dara Meas'), findsOneWidget);
      expect(
        find.byKey(const Key('provider_booking_technician_bk-comp-confirmed')),
        findsNothing,
      );

      // Open the assigned booking detail to verify job progress and assignment.
      await tester.ensureVisible(
        find.byKey(const Key('provider_booking_review_bk-comp-assigned')),
      );
      await tester.tap(
        find.byKey(const Key('provider_booking_review_bk-comp-assigned')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('provider_assigned_technician_row')),
        findsOneWidget,
      );
      expect(find.text('Sokha Vann'), findsOneWidget);
      expect(
        find.byKey(const Key('provider_booking_status_stepper')),
        findsOneWidget,
      );
    });

    testWidgets(
        'Unrelated provider sees empty active work and cannot open another provider booking by URL',
        (tester) async {
      setViewport(tester, 800, 1400);
      final service = BookingService(initialBookings: fixtures);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        wrapDashboard(
          user: unrelatedProviderUser,
          bookingService: service,
          home: const TechnicianHome(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('provider_active_bookings_empty')),
        findsOneWidget,
      );
      expect(find.text('Confirmed Split Wash'), findsNothing);
      expect(find.text('Assigned Chiller Repair'), findsNothing);

      await tester.pumpWidget(
        wrapDashboard(
          user: unrelatedProviderUser,
          bookingService: service,
          home: const ProviderBookingDetailScreen(
            bookingId: 'bk-comp-assigned',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This booking request is unavailable.'), findsOneWidget);
      expect(find.text('Sokha Vann'), findsNothing);
    });

    testWidgets('Error state displays retry button', (tester) async {
      setViewport(tester, 400, 900);
      final service = _FailingActiveBookingsService();
      addTearDown(service.dispose);

      await tester.pumpWidget(
        wrapDashboard(
          user: independentUser,
          bookingService: service,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ProviderBookingList(providerId: independentUser.id),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Unable to load booking requests right now. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    for (final (locale, width) in [
      (const Locale('en'), 320.0),
      (const Locale('km'), 360.0),
    ]) {
      testWidgets(
          'renders active work list cleanly in ${locale.languageCode} at ${width.toInt()}dp with 130% text scale',
          (tester) async {
        setViewport(tester, width, 1000);
        final service = BookingService(initialBookings: fixtures);
        addTearDown(service.dispose);

        await tester.pumpWidget(
          wrapDashboard(
            user: companyUser,
            bookingService: service,
            locale: locale,
            textScale: 1.3,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ProviderBookingList(providerId: companyUser.id),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Assigned Chiller Repair'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
