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
    BookingStatus status = BookingStatus.inProgress,
    String? technicianId = 'tech-a',
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

  group('SCRUM-102 / TECHJOB-3: BookingService.completeTechnicianJob', () {
    test(
        'assigned technician completes an In Progress job and company & homeowner see Completed',
        () async {
      final service = BookingService(
        initialBookings: [booking(id: 'bk-complete-1')],
        customerId: homeowner.id,
      );
      addTearDown(service.dispose);

      final updated = await service.completeTechnicianJob(
        bookingId: 'bk-complete-1',
        technicianId: assignedTech.id,
        companyId: companyId,
      );

      expect(updated.status, BookingStatus.completed);

      final homeownerView =
          await service.watchBookingById('bk-complete-1').first;
      expect(homeownerView?.status, BookingStatus.completed);

      final homeownerHistory =
          await service.getCustomerBookings(homeowner.id);
      expect(
        homeownerHistory.firstWhere((b) => b.id == 'bk-complete-1').status,
        BookingStatus.completed,
      );

      final companyRecords = await service.getProviderServiceRecords(companyId);
      expect(
        companyRecords.firstWhere((b) => b.id == 'bk-complete-1').status,
        BookingStatus.completed,
      );

      final techJobs = await service
          .watchTechnicianJobs(
            technicianId: assignedTech.id,
            companyId: companyId,
          )
          .first;
      expect(techJobs.where((j) => j.id == 'bk-complete-1'), isEmpty);
    });

    test(
        'unassigned technician or technician from another company cannot complete',
        () async {
      final service = BookingService(
        initialBookings: [
          booking(id: 'bk-tech-a', technicianId: 'tech-a'),
          booking(
            id: 'bk-other-co',
            providerId: otherCompanyId,
            technicianId: 'tech-a',
          ),
        ],
        customerId: homeowner.id,
      );
      addTearDown(service.dispose);

      await expectLater(
        () => service.completeTechnicianJob(
          bookingId: 'bk-tech-a',
          technicianId: 'tech-b',
          companyId: companyId,
        ),
        throwsA(isA<UnauthorizedBookingCompletionException>()),
      );

      await expectLater(
        () => service.completeTechnicianJob(
          bookingId: 'bk-other-co',
          technicianId: 'tech-a',
          companyId: companyId,
        ),
        throwsA(isA<UnauthorizedBookingCompletionException>()),
      );

      expect(
        (await service.getBookingById('bk-tech-a'))?.status,
        BookingStatus.inProgress,
      );
      expect(
        (await service.getBookingById('bk-other-co'))?.status,
        BookingStatus.inProgress,
      );
    });

    test('ineligible booking states cannot be completed by technician',
        () async {
      final ineligibleStatuses = [
        BookingStatus.pending,
        BookingStatus.assigned,
        BookingStatus.confirmed,
        BookingStatus.cancelled,
        BookingStatus.declined,
        BookingStatus.completed,
      ];

      final service = BookingService(
        initialBookings: [
          for (final status in ineligibleStatuses)
            booking(id: 'bk-${status.value}', status: status),
        ],
        customerId: homeowner.id,
      );
      addTearDown(service.dispose);

      for (final status in ineligibleStatuses) {
        await expectLater(
          () => service.completeTechnicianJob(
            bookingId: 'bk-${status.value}',
            technicianId: assignedTech.id,
            companyId: companyId,
          ),
          throwsA(isA<InvalidBookingTransitionException>()),
        );
        expect(
          (await service.getBookingById('bk-${status.value}'))?.status,
          status,
        );
      }
    });
  });

  group('SCRUM-102 / TECHJOB-3: FirestoreBookingService.completeTechnicianJob',
      () {
    test(
        'assigned technician completes In Progress job in Firestore; unauthorized and invalid states fail',
        () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreBookingService(firestore: firestore);

      await firestore.collection('bookings').doc('fs-complete-1').set({
        ...booking(id: 'fs-complete-1').toFirestore(),
        'technicianId': assignedTech.id,
        'technicianName': assignedTech.fullName,
      });
      await firestore.collection('bookings').doc('fs-assigned-1').set({
        ...booking(id: 'fs-assigned-1', status: BookingStatus.assigned)
            .toFirestore(),
        'technicianId': assignedTech.id,
        'technicianName': assignedTech.fullName,
      });

      await expectLater(
        () => service.completeTechnicianJob(
          bookingId: 'fs-complete-1',
          technicianId: 'other-tech',
          companyId: companyId,
        ),
        throwsA(isA<UnauthorizedBookingCompletionException>()),
      );

      await expectLater(
        () => service.completeTechnicianJob(
          bookingId: 'fs-assigned-1',
          technicianId: assignedTech.id,
          companyId: companyId,
        ),
        throwsA(isA<InvalidBookingTransitionException>()),
      );

      final completed = await service.completeTechnicianJob(
        bookingId: 'fs-complete-1',
        technicianId: assignedTech.id,
        companyId: companyId,
      );
      expect(completed.status, BookingStatus.completed);

      final persisted = await service.getBookingById('fs-complete-1');
      expect(persisted?.status, BookingStatus.completed);
    });
  });

  group('SCRUM-102 / TECHJOB-3: TechnicianJobDetailScreen UI & cross-role',
      () {
    testWidgets(
        'assigned technician marks In Progress job Completed and company & homeowner see Completed',
        (tester) async {
      setupViewport(tester);

      final service = BookingService(
        initialBookings: [booking(id: 'bk-ui-complete')],
        customerId: homeowner.id,
      );
      addTearDown(service.dispose);

      await tester.pumpWidget(
        screenForUser(
          service,
          user: assignedTech,
          child: const TechnicianJobDetailScreen(bookingId: 'bk-ui-complete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('technician_complete_job_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('technician_start_job_button')),
        findsNothing,
      );

      await tester.ensureVisible(
        find.byKey(const Key('technician_complete_job_button')),
      );
      await tester.tap(find.byKey(const Key('technician_complete_job_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('technician_job_completed_notice')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('technician_complete_job_button')),
        findsNothing,
      );
      expect(find.text('Completed'), findsWidgets);

      final saved = await service.getBookingById('bk-ui-complete');
      expect(saved?.status, BookingStatus.completed);

      // Company admin sees Completed in booking detail.
      await tester.pumpWidget(
        screenForUser(
          service,
          user: companyOwner,
          child: const ProviderBookingDetailScreen(bookingId: 'bk-ui-complete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Completed'), findsWidgets);

      // Homeowner sees Completed in booking tracking.
      await tester.pumpWidget(
        screenForUser(
          service,
          user: homeowner,
          child: const BookingTrackingScreen(bookingId: 'bk-ui-complete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Completed'), findsWidgets);
    });

    testWidgets(
        'Mark as Completed button is hidden when job is not In Progress',
        (tester) async {
      setupViewport(tester);

      final service = BookingService(
        initialBookings: [
          booking(id: 'bk-ui-assigned', status: BookingStatus.assigned),
        ],
        customerId: homeowner.id,
      );
      addTearDown(service.dispose);

      await tester.pumpWidget(
        screenForUser(
          service,
          user: assignedTech,
          child: const TechnicianJobDetailScreen(bookingId: 'bk-ui-assigned'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('technician_complete_job_button')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('technician_start_job_button')),
        findsOneWidget,
      );
    });
  });
}
