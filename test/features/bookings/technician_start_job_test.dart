import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
import 'package:service_pilot/features/bookings/screens/technician_job_detail_screen.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/services/firestore_booking_service.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(this._user);
  final UserModel _user;

  @override
  AuthState build() => AuthStateAuthenticated(_user);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 28, 9, 0);
  final preferred = DateTime(2026, 11, 29, 14, 30);

  const companyId = 'company-a';
  const otherCompanyId = 'company-b';

  const assignedTech = UserModel(
    id: 'tech-a',
    fullName: 'Sokha Vann',
    email: 'tech-a@example.test',
    phoneNumber: '+85512345678',
    role: AppRole.companyTechnician,
    status: 'active',
    companyId: companyId,
    companyName: 'Phnom Penh Fixers',
  );

  const companyOwner = UserModel(
    id: companyId,
    fullName: 'Phnom Penh Fixers',
    email: 'owner@example.test',
    phoneNumber: '+85512345670',
    role: AppRole.company,
    status: 'active',
    companyId: companyId,
    companyName: 'Phnom Penh Fixers',
  );

  const homeowner = UserModel(
    id: 'customer-1',
    fullName: 'Dara Homeowner',
    email: 'dara@example.test',
    phoneNumber: '+85599887766',
    role: AppRole.homeowner,
    status: 'active',
  );

  BookingModel booking({
    required String id,
    String providerId = companyId,
    BookingStatus status = BookingStatus.assigned,
    String? technicianId = 'tech-a',
    String? quoteId,
  }) {
    return BookingModel(
      id: id,
      customerId: homeowner.id,
      providerId: providerId,
      providerName: 'Phnom Penh Fixers',
      serviceCategory: 'Plumbing & Drainage',
      serviceTitle: 'Fix leaking kitchen pipe',
      description: 'Pipe under sink drips continuously.',
      address: 'St. 310, BKK1, Phnom Penh',
      preferredDateTime: preferred,
      confirmedAppointmentAt: preferred,
      status: status,
      totalPrice: 35.0,
      assignedTechnicianId: technicianId,
      assignedTechnicianName: technicianId == null ? null : 'Sokha Vann',
      createdAt: now,
      quoteId: quoteId,
    );
  }

  QuoteRequestModel quote({
    required String id,
    required QuoteStatus status,
    String? bookingId,
  }) {
    return QuoteRequestModel(
      id: id,
      customerId: homeowner.id,
      providerId: companyId,
      providerName: 'Phnom Penh Fixers',
      offeringId: 'off-1',
      offeringTitle: 'Fix leaking kitchen pipe',
      description: 'Pipe under sink drips continuously.',
      status: status,
      createdAt: now,
      updatedAt: now,
      quotedPrice: status == QuoteStatus.requested ? null : 35.0,
      bookingId: bookingId,
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

  Widget screenForUser(
    BookingService service, {
    required UserModel user,
    required Widget child,
  }) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        bookingServiceProvider.overrideWithValue(service),
        authProvider.overrideWith(() => _MockAuthNotifier(user)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('SCRUM-101 / TECHJOB-2: BookingService.startTechnicianJob', () {
    test('assigned technician starts an eligible job and all views see In Progress',
        () async {
      final service = BookingService(
        initialBookings: [booking(id: 'bk-tech-1')],
        customerId: homeowner.id,
      );
      addTearDown(service.dispose);

      final updated = await service.startTechnicianJob(
        bookingId: 'bk-tech-1',
        technicianId: assignedTech.id,
        companyId: companyId,
      );

      expect(updated.status, BookingStatus.inProgress);

      final homeownerView = await service.watchBookingById('bk-tech-1').first;
      expect(homeownerView?.status, BookingStatus.inProgress);

      final companyView =
          await service.watchProviderActiveBookings(companyId).first;
      expect(
        companyView.firstWhere((b) => b.id == 'bk-tech-1').status,
        BookingStatus.inProgress,
      );

      final techView = await service
          .watchTechnicianJobs(
            technicianId: assignedTech.id,
            companyId: companyId,
          )
          .first;
      expect(
        techView.firstWhere((j) => j.id == 'bk-tech-1').status,
        BookingStatus.inProgress,
      );
    });

    test('unassigned technician or technician from another company cannot start',
        () async {
      final service = BookingService(
        initialBookings: [
          booking(id: 'bk-tech-a', technicianId: 'tech-a'),
          booking(id: 'bk-unassigned', technicianId: null, status: BookingStatus.confirmed),
        ],
        customerId: homeowner.id,
      );
      addTearDown(service.dispose);

      // Teammate in same company cannot start tech-a's job.
      await expectLater(
        () => service.startTechnicianJob(
          bookingId: 'bk-tech-a',
          technicianId: 'tech-b',
          companyId: companyId,
        ),
        throwsA(isA<UnauthorizedBookingStartException>()),
      );

      // Technician from another company cannot start tech-a's job.
      await expectLater(
        () => service.startTechnicianJob(
          bookingId: 'bk-tech-a',
          technicianId: 'tech-a',
          companyId: otherCompanyId,
        ),
        throwsA(isA<UnauthorizedBookingStartException>()),
      );

      // Assigned technician cannot start an unassigned booking.
      await expectLater(
        () => service.startTechnicianJob(
          bookingId: 'bk-unassigned',
          technicianId: 'tech-a',
          companyId: companyId,
        ),
        throwsA(isA<UnauthorizedBookingStartException>()),
      );

      expect((await service.getBookingById('bk-tech-a'))?.status,
          BookingStatus.assigned);
      expect((await service.getBookingById('bk-unassigned'))?.status,
          BookingStatus.confirmed);
    });

    test('cancelled job cannot be started', () async {
      final service = BookingService(
        initialBookings: [
          booking(id: 'bk-cancelled', status: BookingStatus.cancelled),
        ],
        customerId: homeowner.id,
      );
      addTearDown(service.dispose);

      await expectLater(
        () => service.startTechnicianJob(
          bookingId: 'bk-cancelled',
          technicianId: assignedTech.id,
          companyId: companyId,
        ),
        throwsA(isA<InvalidBookingStartStateException>()),
      );
      expect((await service.getBookingById('bk-cancelled'))?.status,
          BookingStatus.cancelled);
    });

    test('quote-based job without approval cannot start; approved quote can start',
        () async {
      final quotes = {
        'q-unapproved': quote(id: 'q-unapproved', status: QuoteStatus.quoted),
        'q-approved': quote(
          id: 'q-approved',
          status: QuoteStatus.approved,
          bookingId: 'bk-q-approved',
        ),
      };
      final service = BookingService(
        initialBookings: [
          booking(id: 'bk-q-unapproved', quoteId: 'q-unapproved'),
          booking(id: 'bk-q-approved', quoteId: 'q-approved'),
        ],
        customerId: homeowner.id,
        findQuote: (id) async => quotes[id],
      );
      addTearDown(service.dispose);

      await expectLater(
        () => service.startTechnicianJob(
          bookingId: 'bk-q-unapproved',
          technicianId: assignedTech.id,
          companyId: companyId,
        ),
        throwsA(isA<QuoteNotApprovedForStartException>()),
      );
      expect((await service.getBookingById('bk-q-unapproved'))?.status,
          BookingStatus.assigned);

      final started = await service.startTechnicianJob(
        bookingId: 'bk-q-approved',
        technicianId: assignedTech.id,
        companyId: companyId,
      );
      expect(started.status, BookingStatus.inProgress);
    });
  });

  group('SCRUM-101 / TECHJOB-2: FirestoreBookingService.startTechnicianJob',
      () {
    test('enforces assignment, state, and transactional quote approval',
        () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('bookings').doc('bk-fs-1').set({
        ...booking(id: 'bk-fs-1').toFirestore(),
        'technicianId': assignedTech.id,
        'technicianName': assignedTech.fullName,
      });
      await firestore.collection('bookings').doc('bk-fs-quote').set({
        ...booking(id: 'bk-fs-quote', quoteId: 'q-fs-1').toFirestore(),
        'technicianId': assignedTech.id,
        'technicianName': assignedTech.fullName,
      });
      await firestore.collection('quoteRequests').doc('q-fs-1').set({
        'status': 'quoted',
        'bookingId': 'bk-fs-quote',
      });

      final service = FirestoreBookingService(firestore: firestore);

      // Unassigned technician rejected.
      await expectLater(
        () => service.startTechnicianJob(
          bookingId: 'bk-fs-1',
          technicianId: 'tech-other',
          companyId: companyId,
        ),
        throwsA(isA<UnauthorizedBookingStartException>()),
      );

      // Unapproved quote rejected.
      await expectLater(
        () => service.startTechnicianJob(
          bookingId: 'bk-fs-quote',
          technicianId: assignedTech.id,
          companyId: companyId,
        ),
        throwsA(isA<QuoteNotApprovedForStartException>()),
      );

      // Assigned technician starts eligible job.
      final updated = await service.startTechnicianJob(
        bookingId: 'bk-fs-1',
        technicianId: assignedTech.id,
        companyId: companyId,
      );
      expect(updated.status, BookingStatus.inProgress);
    });
  });

  group('SCRUM-101 / TECHJOB-2: TechnicianJobDetailScreen UI & visibility',
      () {
    testWidgets(
      'assigned technician starts job; company and homeowner views show In Progress',
      (tester) async {
        setupViewport(tester);
        final service = BookingService(
          initialBookings: [booking(id: 'bk-ui-1')],
          customerId: homeowner.id,
        );
        addTearDown(service.dispose);

        await tester.pumpWidget(
          screenForUser(
            service,
            user: assignedTech,
            child: const TechnicianJobDetailScreen(bookingId: 'bk-ui-1'),
          ),
        );
        await tester.pumpAndSettle();

        final startBtn = find.byKey(const Key('technician_start_job_button'));
        expect(startBtn, findsOneWidget);

        await tester.tap(startBtn);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('start_job_dialog')), findsOneWidget);
        await tester.tap(find.byKey(const Key('start_job_confirm_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('technician_job_started_notice')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('technician_start_job_button')),
            findsNothing);
        expect(find.text('In Progress'), findsOneWidget);

        // Company view sees In Progress.
        await tester.pumpWidget(
          screenForUser(
            service,
            user: companyOwner,
            child: const ProviderBookingDetailScreen(bookingId: 'bk-ui-1'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('In Progress'), findsWidgets);

        // Homeowner view sees In Progress.
        await tester.pumpWidget(
          screenForUser(
            service,
            user: homeowner,
            child: const BookingTrackingScreen(bookingId: 'bk-ui-1'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('In Progress'), findsWidgets);
      },
    );

    testWidgets(
      'unapproved quote job shows quote-pending error and stays Assigned',
      (tester) async {
        setupViewport(tester);
        final service = BookingService(
          initialBookings: [
            booking(id: 'bk-ui-quote', quoteId: 'q-pending'),
          ],
          customerId: homeowner.id,
          findQuote: (_) async =>
              quote(id: 'q-pending', status: QuoteStatus.quoted),
        );
        addTearDown(service.dispose);

        await tester.pumpWidget(
          screenForUser(
            service,
            user: assignedTech,
            child: const TechnicianJobDetailScreen(bookingId: 'bk-ui-quote'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('technician_start_job_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('start_job_confirm_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('technician_job_error_notice')),
          findsOneWidget,
        );
        expect((await service.getBookingById('bk-ui-quote'))?.status,
            BookingStatus.assigned);
      },
    );

    testWidgets(
      'unassigned or cancelled job shows unavailable and hides Start Job',
      (tester) async {
        setupViewport(tester);
        final service = BookingService(
          initialBookings: [
            booking(id: 'bk-other-tech', technicianId: 'tech-b'),
            booking(id: 'bk-cancelled', status: BookingStatus.cancelled),
          ],
          customerId: homeowner.id,
        );
        addTearDown(service.dispose);

        await tester.pumpWidget(
          screenForUser(
            service,
            user: assignedTech,
            child: const TechnicianJobDetailScreen(bookingId: 'bk-other-tech'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('technician_job_unavailable')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('technician_start_job_button')),
            findsNothing);

        await tester.pumpWidget(
          screenForUser(
            service,
            user: assignedTech,
            child: const TechnicianJobDetailScreen(bookingId: 'bk-cancelled'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('technician_job_unavailable')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('technician_start_job_button')),
            findsNothing);
      },
    );
  });
}
