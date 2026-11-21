import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/screens/booking_tracking_screen.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildBookingTrackingTestApp({
    required String bookingId,
    IBookingService? customService,
    String activeCustomerId = BookingService.defaultCustomerId,
  }) {
    final service =
        customService ?? BookingService(customerId: activeCustomerId);

    final router = GoRouter(
      initialLocation: '/bookings/$bookingId',
      routes: [
        GoRoute(
          path: '/bookings/:bookingId',
          builder: (_, state) {
            final id = state.pathParameters['bookingId'] ?? '';
            final extra = state.extra as BookingModel?;
            return BookingTrackingScreen(
              bookingId: id,
              initialBooking: extra,
            );
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        activeCustomerIdProvider.overrideWithValue(activeCustomerId),
        bookingServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  group('SCRUM-44 / US-13: Track Repair Booking Status Widget Tests', () {
    testWidgets(
      'AC 1 & DoD 1: Tracking screen displays timeline stepper and current status',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingTrackingTestApp(
            bookingId: 'bk-pending-01',
            customService: service,
          ),
        );
        await tester.pumpAndSettle();

        // Status badge and summary
        expect(find.text('Pending'), findsOneWidget);
        expect(find.byKey(const Key('booking_status_stepper')), findsOneWidget);
        expect(find.text('Service Progress'), findsOneWidget);

        // Milestone titles in stepper
        expect(find.text('Request Submitted'), findsOneWidget);
        expect(find.text('Booking Confirmed'), findsOneWidget);
        expect(find.text('Technician Assigned'), findsOneWidget);
        expect(find.text('Repair In Progress'), findsOneWidget);
        expect(find.text('Repair Completed'), findsOneWidget);
      },
    );

    testWidgets(
      'AC 4: Assigned technician details are displayed when available',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingTrackingTestApp(
            bookingId: 'bk-assigned-02',
            customService: service,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Assigned'), findsOneWidget);
        expect(find.text('Sokha Vann'), findsWidgets);
        expect(find.text('Assigned Technician'), findsOneWidget);
        expect(find.text('Assigned to Sokha Vann'), findsOneWidget);
      },
    );

    testWidgets(
      'AC 2: Cancelled booking displays cancellation terminal milestone',
      (tester) async {
        final booking = BookingModel(
          id: 'bk-cancelled-test',
          customerId: BookingService.defaultCustomerId,
          providerId: 'prov-1',
          providerName: 'CoolAir',
          serviceCategory: 'AC Repair',
          serviceTitle: 'AC Check',
          description: 'AC leak',
          address: 'Toul Kork',
          preferredDateTime: DateTime(2026, 11, 25),
          status: BookingStatus.cancelled,
          cancellationReason: 'Found another provider',
          createdAt: DateTime(2026, 11, 20),
        );

        final service = BookingService(initialBookings: [booking]);
        await tester.pumpWidget(
          buildBookingTrackingTestApp(
            bookingId: 'bk-cancelled-test',
            customService: service,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cancelled'), findsOneWidget);
        expect(find.text('Booking Cancelled'), findsOneWidget);
        expect(
          find.text('Cancellation reason: Found another provider'),
          findsOneWidget,
        );
        expect(
          find.text('The repair booking was cancelled.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC 2: Declined booking displays declined terminal milestone',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingTrackingTestApp(
            bookingId: 'bk-declined-06',
            customService: service,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Declined'), findsOneWidget);
        expect(find.text('Request Declined'), findsOneWidget);
        expect(
          find.text('Service provider could not accept this request'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC 5: Tenant Data Isolation blocks customer from modifying another users booking',
      (tester) async {
        final service = BookingService();
        // Active customer is customer-1, attempting to open bk-other-customer-99
        await tester.pumpWidget(
          buildBookingTrackingTestApp(
            bookingId: 'bk-other-customer-99',
            customService: service,
            activeCustomerId: 'customer-1',
          ),
        );
        await tester.pumpAndSettle();

        // Customer cannot cancel another customer's booking
        expect(find.byKey(const Key('cancel_booking_button')), findsNothing);
        expect(
          find.byKey(const Key('cancellation_restricted_notice')),
          findsOneWidget,
        );
        expect(
          find.text('Only the customer who created this booking can cancel it.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC 3: Status changes made by provider update customer view in real-time',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingTrackingTestApp(
            bookingId: 'bk-pending-01',
            customService: service,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pending'), findsOneWidget);

        // Provider accepts the booking in backend/database
        await service.acceptBooking(
          bookingId: 'bk-pending-01',
          providerId: 'prov-ac-01',
        );

        // Screen automatically receives the live update
        await tester.pumpAndSettle();

        expect(find.text('Confirmed'), findsOneWidget);
      },
    );

    testWidgets(
      'AC 6: Pull to refresh refreshes booking details',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingTrackingTestApp(
            bookingId: 'bk-pending-01',
            customService: service,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('booking_tracking_refresh_indicator')),
          findsOneWidget,
        );

        // Trigger pull-to-refresh
        await tester.fling(
          find.byKey(const Key('booking_tracking_refresh_indicator')),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();

        expect(find.text('Pending'), findsOneWidget);
      },
    );
  });
}
