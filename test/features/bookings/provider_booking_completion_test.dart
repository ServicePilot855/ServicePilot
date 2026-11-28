import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/screens/provider_booking_detail_screen.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/l10n/l10n.dart';

void main() {
  const providerId = 'prov-virak-ac';
  const companyId = 'prov-fixco-company';
  const otherProviderId = 'prov-other-99';
  const customerId = 'customer-1';

  const independentUser = UserModel(
    id: providerId,
    fullName: 'Virak Chan',
    email: 'virak@servicepilot.app',
    phoneNumber: '+855 12 111 222',
    role: AppRole.independentProvider,
    status: 'active',
  );

  const otherProviderUser = UserModel(
    id: otherProviderId,
    fullName: 'Other Provider',
    email: 'other@servicepilot.app',
    phoneNumber: '+855 12 999 888',
    role: AppRole.independentProvider,
    status: 'active',
  );

  BookingModel makeBooking({
    String id = 'bk-in-progress-1',
    String ownerProviderId = providerId,
    BookingStatus status = BookingStatus.inProgress,
  }) {
    final now = DateTime(2026, 11, 28, 10, 0);
    return BookingModel(
      id: id,
      customerId: customerId,
      providerId: ownerProviderId,
      providerName: 'Virak Chan AC',
      serviceCategory: 'AC Repair',
      serviceTitle: 'Split AC Deep Cleaning',
      description: 'Inverter AC leaking water in living room.',
      address: 'St 271, Toul Kork, Phnom Penh',
      preferredDateTime: now.add(const Duration(days: 1)),
      confirmedAppointmentAt: now.add(const Duration(days: 1)),
      status: status,
      totalPrice: 35.0,
      createdAt: now,
    );
  }

  Widget buildDetailTestApp({
    required BookingService service,
    required UserModel actor,
    required String bookingId,
  }) {
    return ProviderScope(
      overrides: [
        bookingServiceProvider.overrideWithValue(service),
        currentUserProvider.overrideWithValue(actor),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProviderBookingDetailScreen(bookingId: bookingId),
      ),
    );
  }

  group('SCRUM-92 / WORK-2 (Service): Provider Work Completion', () {
    test(
      'Independent provider completes owned In Progress job and updates both histories',
      () async {
        final service = BookingService(
          initialBookings: [makeBooking()],
          customerId: customerId,
        );

        final updated = await service.completeBooking(
          bookingId: 'bk-in-progress-1',
          providerId: providerId,
        );

        expect(updated.status, BookingStatus.completed);

        final activeJobs = await service.getProviderActiveBookings(providerId);
        expect(activeJobs, isEmpty);

        final providerHistory =
            await service.getProviderServiceRecords(providerId);
        expect(providerHistory.map((r) => r.id), contains('bk-in-progress-1'));
        expect(providerHistory.first.status, BookingStatus.completed);

        final customerHistory = await service.getCustomerBookings(customerId);
        expect(customerHistory.first.status, BookingStatus.completed);
      },
    );

    test('Company admin completes owned In Progress job', () async {
      final service = BookingService(
        initialBookings: [
          makeBooking(id: 'bk-co-1', ownerProviderId: companyId),
        ],
        customerId: customerId,
      );

      final updated = await service.completeBooking(
        bookingId: 'bk-co-1',
        providerId: companyId,
      );

      expect(updated.status, BookingStatus.completed);
    });

    test('Unrelated provider cannot complete another provider job', () async {
      final service = BookingService(
        initialBookings: [makeBooking()],
        customerId: customerId,
      );

      await expectLater(
        () => service.completeBooking(
          bookingId: 'bk-in-progress-1',
          providerId: otherProviderId,
        ),
        throwsA(isA<UnauthorizedBookingCompletionException>()),
      );

      final persisted = await service.getBookingById('bk-in-progress-1');
      expect(persisted?.status, BookingStatus.inProgress);
    });

    test('Ineligible booking states cannot be marked completed', () async {
      final ineligibleStatuses = [
        BookingStatus.pending,
        BookingStatus.confirmed,
        BookingStatus.assigned,
        BookingStatus.cancelled,
        BookingStatus.declined,
        BookingStatus.completed,
      ];

      for (final status in ineligibleStatuses) {
        final id = 'bk-${status.value}';
        final service = BookingService(
          initialBookings: [makeBooking(id: id, status: status)],
          customerId: customerId,
        );

        await expectLater(
          () => service.completeBooking(bookingId: id, providerId: providerId),
          throwsA(isA<InvalidBookingTransitionException>()),
        );
      }
    });
  });

  group('SCRUM-92 / WORK-2 (Widget): ProviderBookingDetailScreen Completion', () {
    testWidgets(
      'Authorized provider sees Mark as Completed on In Progress booking and completes it',
      (tester) async {
        final service = BookingService(
          initialBookings: [makeBooking()],
          customerId: customerId,
        );

        await tester.pumpWidget(
          buildDetailTestApp(
            service: service,
            actor: independentUser,
            bookingId: 'bk-in-progress-1',
          ),
        );
        await tester.pumpAndSettle();

        final completeButton =
            find.byKey(const Key('provider_complete_booking_button'));
        expect(completeButton, findsOneWidget);

        await tester.ensureVisible(completeButton);
        await tester.tap(completeButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('provider_booking_completed_notice')),
          findsOneWidget,
        );
        expect(completeButton, findsNothing);

        final persisted = await service.getBookingById('bk-in-progress-1');
        expect(persisted?.status, BookingStatus.completed);
      },
    );

    testWidgets(
      'Confirmed booking does not show Mark as Completed button',
      (tester) async {
        final service = BookingService(
          initialBookings: [
            makeBooking(id: 'bk-confirmed', status: BookingStatus.confirmed),
          ],
          customerId: customerId,
        );

        await tester.pumpWidget(
          buildDetailTestApp(
            service: service,
            actor: independentUser,
            bookingId: 'bk-confirmed',
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('provider_complete_booking_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Unrelated provider is blocked and does not see Mark as Completed button',
      (tester) async {
        final service = BookingService(
          initialBookings: [makeBooking()],
          customerId: customerId,
        );

        await tester.pumpWidget(
          buildDetailTestApp(
            service: service,
            actor: otherProviderUser,
            bookingId: 'bk-in-progress-1',
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('provider_complete_booking_button')),
          findsNothing,
        );
        expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
        expect(find.text('Split AC Deep Cleaning'), findsNothing);
      },
    );
  });
}
