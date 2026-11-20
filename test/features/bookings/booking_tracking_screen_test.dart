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

  group('SCRUM-45 / US-14: BookingTrackingScreen Cancellation Widget Tests', () {
    testWidgets(
      'customer must confirm decision before cancellation; choosing Keep Booking retains Pending status',
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
        final cancelBtn = find.byKey(const Key('cancel_booking_button'));
        await tester.scrollUntilVisible(
          cancelBtn,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(cancelBtn, findsOneWidget);

        // Tap Cancel Booking -> opens confirmation modal
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('cancel_booking_confirmation_dialog')),
          findsOneWidget,
        );
        expect(find.text('Cancel Repair Booking?'), findsOneWidget);

        // Tap Keep Booking -> dismisses dialog without cancelling
        await tester.tap(find.byKey(const Key('cancel_dialog_keep_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('cancel_booking_confirmation_dialog')),
          findsNothing,
        );
        expect(find.text('Pending'), findsOneWidget);

        final booking = await service.getBookingById('bk-pending-01');
        expect(booking?.status.label, equals('Pending'));
      },
    );

    testWidgets(
      'confirming cancellation updates status to Cancelled and hides Cancel button',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingTrackingTestApp(
            bookingId: 'bk-confirmed-03',
            customService: service,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Confirmed'), findsOneWidget);
        final cancelBtn = find.byKey(const Key('cancel_booking_button'));
        await tester.scrollUntilVisible(
          cancelBtn,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Enter optional cancellation reason and confirm
        await tester.enterText(
          find.byKey(const Key('cancel_booking_reason_field')),
          'Fixed breaker myself',
        );
        await tester.tap(find.byKey(const Key('cancel_dialog_confirm_button')));
        await tester.pumpAndSettle();

        // Status changes to Cancelled and success notice appears
        expect(find.text('Cancelled'), findsOneWidget);
        expect(
          find.byKey(const Key('booking_cancelled_success_notice')),
          findsOneWidget,
        );
        expect(
          find.textContaining('Fixed breaker myself'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('cancel_booking_button')), findsNothing);
      },
    );

    testWidgets(
      'In Progress and Completed bookings cannot be cancelled and hide Cancel button',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingTrackingTestApp(
            bookingId: 'bk-inprogress-04',
            customService: service,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('In Progress'), findsOneWidget);
        expect(find.byKey(const Key('cancel_booking_button')), findsNothing);
        expect(
          find.byKey(const Key('cancellation_restricted_notice')),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'cannot be cancelled because the repair is already In Progress',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'non-owner customer cannot cancel another customer booking',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingTrackingTestApp(
            bookingId: 'bk-other-customer-99',
            customService: service,
            activeCustomerId: BookingService.defaultCustomerId,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('cancel_booking_button')), findsNothing);
        expect(
          find.text(
            'Only the customer who created this booking can cancel it.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
