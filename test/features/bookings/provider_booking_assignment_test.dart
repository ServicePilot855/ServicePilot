import 'dart:async';

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
import 'package:service_pilot/features/bookings/screens/provider_booking_detail_screen.dart';
import 'package:service_pilot/features/bookings/services/firestore_booking_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

const company = UserModel(
  id: 'company-a',
  fullName: 'Company Owner',
  email: 'owner@example.test',
  phoneNumber: '',
  role: AppRole.company,
  status: 'active',
);

class _Auth extends AuthNotifier {
  _Auth(this.user);

  final UserModel user;

  @override
  AuthState build() => AuthStateAuthenticated(user);
}

class _DelayedRosterService extends FirestoreBookingService {
  _DelayedRosterService(FakeFirebaseFirestore firestore)
      : super(firestore: firestore);

  final firstLoad = Completer<Map<String, String>>();
  bool _startedLoading = false;

  @override
  Future<Map<String, String>> getAssignableTechnicians(String companyId) {
    if (_startedLoading) return super.getAssignableTechnicians(companyId);
    _startedLoading = true;
    return firstLoad.future;
  }
}

BookingModel booking(BookingStatus status) => BookingModel(
      id: 'booking-a',
      customerId: 'customer-a',
      providerId: company.id,
      providerName: 'Company A',
      serviceCategory: 'Plumbing',
      serviceTitle: 'Sink repair',
      description: 'Leaking sink',
      address: 'Street 310, Phnom Penh',
      preferredDateTime: DateTime(2026, 12, 1, 9),
      confirmedAppointmentAt: DateTime(2026, 12, 1, 9),
      status: status,
      totalPrice: 20,
      createdAt: DateTime(2026, 11, 28),
    );

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreBookingService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FirestoreBookingService(firestore: firestore);
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    UserModel? user,
    BookingStatus status = BookingStatus.confirmed,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final model = booking(status);
    await firestore.doc('bookings/${model.id}').set(model.toFirestore());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingServiceProvider.overrideWithValue(service),
          authProvider.overrideWith(() => _Auth(user ?? company)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: ProviderBookingDetailScreen(bookingId: model.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addTechnician(String companyId, String id, String name) =>
      firestore.doc('providers/$companyId/technicians/$id').set({
        'id': id,
        'fullName': name,
      });

  final openPicker = find.byKey(const Key('provider_open_assignment_button'));
  final saveChoice = find.byKey(const Key('provider_save_assignment_button'));

  testWidgets('company chooses one roster technician and sees the assignment',
      (tester) async {
    await addTechnician(company.id, 'tech-a', 'Borey Nhem');
    await addTechnician(company.id, 'tech-b', 'Sokha Vann');
    await addTechnician('company-b', 'tech-c', 'Other Company Technician');
    await pumpDetail(tester);

    await tester.ensureVisible(openPicker);
    await tester.tap(openPicker);
    await tester.pumpAndSettle();
    expect(find.text('Borey Nhem'), findsOneWidget);
    expect(find.text('Sokha Vann'), findsOneWidget);
    expect(find.text('Other Company Technician'), findsNothing);
    expect(
        tester
            .widget<ElevatedButton>(find.descendant(
              of: saveChoice,
              matching: find.byType(ElevatedButton),
            ))
            .onPressed,
        isNull);

    await tester.tap(find.text('Sokha Vann'));
    await tester.pumpAndSettle();
    await tester.tap(saveChoice);
    await tester.pumpAndSettle();

    expect(find.text('Sokha Vann'), findsOneWidget);
    expect(find.text('Assigned'), findsWidgets);
    expect(openPicker, findsNothing);
    expect(
        find.byKey(const Key('provider_confirm_booking_button')), findsNothing);
    final stored = (await service.getBookingById('booking-a'))!;
    expect(stored.assignedTechnicianId, 'tech-b');
    expect(stored.assignedTechnicianName, 'Sokha Vann');
    expect(stored.confirmedAppointmentAt, DateTime(2026, 12, 1, 9));
  });

  testWidgets('empty roster is usable in Khmer at 130% text scale',
      (tester) async {
    await pumpDetail(tester, locale: const Locale('km'));
    await tester.ensureVisible(openPicker);
    await tester.tap(openPicker);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('provider_assignment_empty')), findsOneWidget);
    expect(saveChoice, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('independent providers cannot open the picker', (tester) async {
    await pumpDetail(tester,
        user: company.copyWith(role: AppRole.independentProvider));
    expect(openPicker, findsNothing);
    expect(find.text('Sink repair'), findsOneWidget);
  });

  testWidgets('loads the roster again after an error', (tester) async {
    final delayed = _DelayedRosterService(firestore);
    service = delayed;
    await addTechnician(company.id, 'tech-a', 'Borey Nhem');
    await pumpDetail(tester);
    await tester.ensureVisible(openPicker);
    await tester.tap(openPicker);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(saveChoice, findsNothing);

    delayed.firstLoad.completeError(StateError('Roster unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load your technicians. Try again.'),
        findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Borey Nhem'), findsOneWidget);
  });

  testWidgets('a technician removed after selection cannot be assigned',
      (tester) async {
    await addTechnician(company.id, 'tech-a', 'Borey Nhem');
    await pumpDetail(tester);
    await tester.ensureVisible(openPicker);
    await tester.tap(openPicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borey Nhem'));
    await tester.pumpAndSettle();
    await firestore.doc('providers/${company.id}/technicians/tech-a').delete();
    await tester.tap(saveChoice);
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('provider_booking_error_notice')), findsOneWidget);
    final stored = (await service.getBookingById('booking-a'))!;
    expect(stored.status, BookingStatus.confirmed);
    expect(stored.assignedTechnicianId, isNull);
  });

  testWidgets('cancelled bookings do not offer assignment', (tester) async {
    await pumpDetail(tester, status: BookingStatus.cancelled);
    expect(openPicker, findsNothing);
  });
}
