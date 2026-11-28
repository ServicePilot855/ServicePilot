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
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/technician_job.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/services/firestore_booking_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

/// TECHJOB-1 (SCRUM-100): a company technician sees the jobs assigned to
/// them, with the appointment, service and status, and nothing else.
///
/// SCRUM-180 checks three people: the assigned technician, a teammate in the
/// same company, and a technician from another company.

class _SignedIn extends AuthNotifier {
  _SignedIn(this.user);
  final UserModel user;

  @override
  AuthState build() => AuthStateAuthenticated(user);
}

class _FailingJobsService extends BookingService {
  _FailingJobsService() : super(initialBookings: const []);

  @override
  Stream<List<TechnicianJob>> watchTechnicianJobs({
    required String technicianId,
    required String companyId,
  }) =>
      Stream.error(Exception('network unavailable'));
}

const companyA = 'company-a';
const companyB = 'company-b';

UserModel technician(String id, String companyId, {String status = 'active'}) =>
    UserModel(
      id: id,
      fullName: 'Technician $id',
      email: '$id@example.test',
      phoneNumber: '',
      role: AppRole.companyTechnician,
      status: status,
      companyId: companyId,
      companyName: 'Company $companyId',
    );

final assigned = technician('tech-a', companyA);
final teammate = technician('tech-b', companyA);
final outsider = technician('tech-c', companyB);

const homeowner = UserModel(
  id: 'customer-1',
  fullName: 'Dara Homeowner',
  email: 'dara@example.test',
  phoneNumber: '',
  role: AppRole.homeowner,
  status: 'active',
);

BookingModel booking(
  String id, {
  String providerId = companyA,
  required BookingStatus status,
  String? technicianId,
  required DateTime at,
  bool confirmed = true,
}) =>
    BookingModel(
      id: id,
      customerId: 'customer-1',
      providerId: providerId,
      providerName: 'Company $providerId',
      serviceCategory: 'Plumbing & Drainage',
      serviceTitle: 'Job $id',
      description: 'Kitchen tap drips all night.',
      address: 'St. 310, Boeung Keng Kang 1, Phnom Penh',
      preferredDateTime: at,
      confirmedAppointmentAt: confirmed ? at : null,
      status: status,
      totalPrice: 42.5,
      assignedTechnicianId: technicianId,
      assignedTechnicianName:
          technicianId == null ? null : 'Tech $technicianId',
      createdAt: DateTime(2026, 11, 20),
    );

List<BookingModel> fixtures() => [
      // Two active jobs for tech-a; the later one is listed second.
      booking('assigned',
          status: BookingStatus.assigned,
          technicianId: 'tech-a',
          at: DateTime(2026, 12, 2, 9)),
      booking('progress',
          status: BookingStatus.inProgress,
          technicianId: 'tech-a',
          at: DateTime(2026, 12, 1, 14)),
      // Not visible to tech-a: unassigned, closed, someone else's, or another
      // company's booking that happens to carry tech-a's ID.
      booking('confirmed',
          status: BookingStatus.confirmed, at: DateTime(2026, 12, 3, 9)),
      booking('completed',
          status: BookingStatus.completed,
          technicianId: 'tech-a',
          at: DateTime(2026, 11, 25, 9)),
      booking('cancelled',
          status: BookingStatus.cancelled,
          technicianId: 'tech-a',
          at: DateTime(2026, 12, 4, 9)),
      booking('teammate',
          status: BookingStatus.assigned,
          technicianId: 'tech-b',
          at: DateTime(2026, 12, 5, 9)),
      booking('other-company',
          providerId: companyB,
          status: BookingStatus.assigned,
          technicianId: 'tech-a',
          at: DateTime(2026, 12, 6, 9)),
    ];

Future<List<String>> jobIds(IBookingService service, UserModel user) async {
  final jobs = await service
      .watchTechnicianJobs(technicianId: user.id, companyId: user.companyId!)
      .first;
  return [for (final job in jobs) job.id];
}

Future<String?> jobId(
    IBookingService service, UserModel user, String id) async {
  final job = await service
      .watchTechnicianJob(
        technicianId: user.id,
        companyId: user.companyId!,
        bookingId: id,
      )
      .first;
  return job?.id;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SCRUM-178: jobs are read for the signed-in technician only', () {
    test('only Assigned and In Progress count as technician jobs', () {
      expect(
        BookingStatus.values.where((s) => s.isTechnicianJob).toSet(),
        {BookingStatus.assigned, BookingStatus.inProgress},
      );
    });

    test('only an active technician linked to a company may view jobs', () {
      expect(assigned.canViewAssignedJobs, isTrue);
      expect(technician('x', companyA, status: 'suspended').canViewAssignedJobs,
          isFalse);
      expect(technician('x', '').canViewAssignedJobs, isFalse);
      expect(homeowner.canViewAssignedJobs, isFalse);
    });

    Future<IBookingService> inMemory() async =>
        BookingService(initialBookings: fixtures());

    Future<IBookingService> firestore() async {
      final db = FakeFirebaseFirestore();
      for (final b in fixtures()) {
        await db.collection('bookings').doc(b.id).set(b.toFirestore());
      }
      return FirestoreBookingService(firestore: db);
    }

    for (final (name, build) in [
      ('in-memory', inMemory),
      ('Firestore', firestore),
    ]) {
      test('$name: each technician gets only their own active jobs', () async {
        final service = await build();
        expect(await jobIds(service, assigned), ['progress', 'assigned']);
        expect(await jobIds(service, teammate), ['teammate']);
        expect(await jobIds(service, outsider), isEmpty);
      });

      test('$name: one job opens only for its assigned technician', () async {
        final service = await build();
        expect(await jobId(service, assigned, 'assigned'), 'assigned');
        expect(await jobId(service, teammate, 'assigned'), isNull);
        expect(await jobId(service, outsider, 'assigned'), isNull);
        expect(await jobId(service, outsider, 'other-company'), isNull);
        expect(await jobId(service, assigned, 'other-company'), isNull);
        expect(await jobId(service, assigned, 'cancelled'), isNull);
        expect(await jobId(service, assigned, 'completed'), isNull);
        expect(await jobId(service, assigned, 'missing'), isNull);
      });
    }

    test('a job carries the appointment, service and status only', () {
      final job = TechnicianJob.fromBooking(fixtures().first);
      expect(job.id, 'assigned');
      expect(job.companyId, companyA);
      expect(job.serviceTitle, 'Job assigned');
      expect(job.serviceCategory, 'Plumbing & Drainage');
      expect(job.status, BookingStatus.assigned);
      expect(job.appointmentAt, DateTime(2026, 12, 2, 9));
      expect(job.isAppointmentConfirmed, isTrue);
      expect(job.address, isNotEmpty);
      expect(job.description, isNotEmpty);
    });

    test('a status change reaches the technician live', () async {
      final service = BookingService(initialBookings: fixtures());
      addTearDown(service.dispose);
      final updates = service.watchTechnicianJobs(
        technicianId: assigned.id,
        companyId: companyA,
      );
      final statuses = updates
          .map((jobs) => jobs.firstWhere((j) => j.id == 'assigned').status)
          .take(2)
          .toList();
      await Future<void>.delayed(Duration.zero);
      await service.startBooking(bookingId: 'assigned', providerId: companyA);
      expect(
          await statuses, [BookingStatus.assigned, BookingStatus.inProgress]);
    });
  });

  group('SCRUM-179 / SCRUM-180: technician jobs screens', () {
    void setViewport(WidgetTester tester, double width) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Future<AppLocalizations> openApp(
      WidgetTester tester,
      UserModel user,
      String path, {
      IBookingService? service,
      Locale locale = const Locale('en'),
      double width = 360,
      double textScale = 1.3,
    }) async {
      setViewport(tester, width);
      final bookings = service ?? BookingService(initialBookings: fixtures());
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(() => _SignedIn(user)),
        bookingServiceProvider.overrideWithValue(bookings),
      ]);
      final router = container.read(appRouterProvider);
      if (bookings is BookingService) addTearDown(bookings.dispose);
      addTearDown(container.dispose);
      addTearDown(router.dispose);
      router.go(path);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
    }

    testWidgets('the assigned technician sees their jobs and opens one',
        (tester) async {
      final l10n =
          await openApp(tester, assigned, AppRole.companyTechnician.homeRoute);

      expect(find.text(l10n.technicianJobsTitle), findsOneWidget);
      expect(find.text(l10n.homeComingSoonNotice), findsNothing);
      expect(find.byKey(const Key('technician_job_card_progress')),
          findsOneWidget);
      expect(find.byKey(const Key('technician_job_card_assigned')),
          findsOneWidget);
      for (final hidden in [
        'confirmed',
        'completed',
        'cancelled',
        'teammate',
        'other-company',
      ]) {
        expect(find.byKey(Key('technician_job_card_$hidden')), findsNothing);
      }
      expect(find.byKey(const Key('technician_job_status_assigned')),
          findsOneWidget);

      final card = find.byKey(const Key('technician_job_card_assigned'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.text(l10n.technicianJobDetailTitle), findsOneWidget);
      expect(find.text('Job assigned'), findsOneWidget);
      expect(find.byKey(const Key('technician_job_detail_status')),
          findsOneWidget);
      expect(find.text(l10n.technicianJobAppointmentLabel), findsOneWidget);
      expect(
          find.text('St. 310, Boeung Keng Kang 1, Phnom Penh'), findsOneWidget);
      expect(find.text('Plumbing & Drainage'), findsOneWidget);
      expect(find.text('Kitchen tap drips all night.'), findsOneWidget);
      // The price and the homeowner's details are not shown to technicians.
      expect(find.textContaining('42.5'), findsNothing);
      expect(find.textContaining('customer-1'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a teammate in the same company sees an empty list',
        (tester) async {
      final service = BookingService(
        initialBookings: fixtures().where((b) => b.id != 'teammate').toList(),
      );
      final l10n = await openApp(
        tester,
        teammate,
        AppRole.companyTechnician.homeRoute,
        service: service,
      );

      expect(find.byKey(const Key('technician_jobs_empty')), findsOneWidget);
      expect(find.text(l10n.technicianJobsEmpty), findsOneWidget);
      expect(
          find.byKey(const Key('technician_job_card_assigned')), findsNothing);
    });

    for (final (who, user) in [
      ('teammate', teammate),
      ('other company', outsider)
    ]) {
      testWidgets('a technician from the $who cannot open the job',
          (tester) async {
        final l10n = await openApp(tester, user, '/technician/jobs/assigned');

        expect(find.byKey(const Key('technician_job_unavailable')),
            findsOneWidget);
        expect(find.text(l10n.technicianJobUnavailable), findsOneWidget);
        expect(find.text('Job assigned'), findsNothing);
        expect(
            find.text('St. 310, Boeung Keng Kang 1, Phnom Penh'), findsNothing);
      });
    }

    testWidgets('a cancelled job does not open for its technician',
        (tester) async {
      await openApp(tester, assigned, '/technician/jobs/cancelled');
      expect(
          find.byKey(const Key('technician_job_unavailable')), findsOneWidget);
      expect(find.text('Job cancelled'), findsNothing);
    });

    testWidgets('people who are not company technicians are sent home',
        (tester) async {
      final l10n =
          await openApp(tester, homeowner, '/technician/jobs/assigned');
      expect(find.text(l10n.technicianJobDetailTitle), findsNothing);
      expect(find.byKey(const Key('technician_job_unavailable')), findsNothing);
      expect(find.byKey(const Key('technician_job_appointment_row')),
          findsNothing);
    });

    testWidgets('a load failure explains it and offers a retry',
        (tester) async {
      final l10n = await openApp(
        tester,
        assigned,
        AppRole.companyTechnician.homeRoute,
        service: _FailingJobsService(),
      );
      expect(find.byKey(const Key('technician_jobs_error')), findsOneWidget);
      expect(find.text(l10n.bookingInboxRetry), findsOneWidget);
    });

    for (final locale in [const Locale('en'), const Locale('km')]) {
      for (final width in [320.0, 360.0]) {
        testWidgets(
            'list and detail fit in ${locale.languageCode} at ${width.toInt()}dp and 130% text',
            (tester) async {
          await openApp(
            tester,
            assigned,
            AppRole.companyTechnician.homeRoute,
            locale: locale,
            width: width,
          );
          expect(tester.takeException(), isNull);

          final card = find.byKey(const Key('technician_job_card_progress'));
          await tester.ensureVisible(card);
          expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
          await tester.tap(card);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('technician_job_appointment_row')),
              findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
