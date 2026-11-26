import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/screens/booking_history_screen.dart';
import 'package:service_pilot/features/bookings/screens/booking_tracking_screen.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildBookingHistoryTestApp({
    IBookingService? customService,
    String activeCustomerId = BookingService.defaultCustomerId,
    String initialLocation = '/bookings/history',
  }) {
    final service =
        customService ?? BookingService(customerId: activeCustomerId);

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/bookings/history',
          builder: (_, __) => const BookingHistoryScreen(),
        ),
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

  group('SCRUM-46 / US-15: View Repair Booking History Widget Tests', () {
    testWidgets(
      'AC 1 & DoD 1: Renders Booking History screen with Active and Past tabs',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingHistoryTestApp(customService: service),
        );
        await tester.pumpAndSettle();

        expect(find.text('Booking History'), findsOneWidget);
        expect(
          find.byKey(const Key('booking_history_tab_active')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('booking_history_tab_past')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC 2 & AC 4: Active tab shows only active bookings with provider, date, and status',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingHistoryTestApp(customService: service),
        );
        await tester.pumpAndSettle();

        // Active tab is selected by default
        // Default bookings contain:
        // Active: bk-pending-01, bk-assigned-02, bk-confirmed-03, bk-inprogress-04
        expect(
          find.byKey(const Key('booking_history_card_bk-pending-01')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('booking_history_card_bk-assigned-02')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('booking_history_card_bk-confirmed-03')),
          findsOneWidget,
        );

        // Terminal bookings should not be visible in Active tab
        expect(
          find.byKey(const Key('booking_history_card_bk-completed-05')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('booking_history_card_bk-declined-06')),
          findsNothing,
        );

        // Card displays provider name and formatted appointment date
        expect(
          find.text('Phnom Penh CoolAir Engineering'),
          findsOneWidget,
        );
        expect(
          find.text('AC Deep Chemical Wash & Gas Check'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC 4: Switching to Past tab displays completed, cancelled, and declined bookings',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingHistoryTestApp(customService: service),
        );
        await tester.pumpAndSettle();

        // Switch to Past tab
        await tester.tap(find.byKey(const Key('booking_history_tab_past')));
        await tester.pumpAndSettle();

        // Completed and Declined bookings are shown
        expect(
          find.byKey(const Key('booking_history_card_bk-completed-05')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('booking_history_card_bk-declined-06')),
          findsOneWidget,
        );
        expect(find.text('CleanNest Phnom Penh Co.'), findsOneWidget);

        // Active bookings are not shown in Past tab
        expect(
          find.byKey(const Key('booking_history_card_bk-pending-01')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC 3: Selecting a booking navigates to its tracking details',
      (tester) async {
        final service = BookingService();
        await tester.pumpWidget(
          buildBookingHistoryTestApp(customService: service),
        );
        await tester.pumpAndSettle();

        final cardFinder = find.byKey(
          const Key('booking_history_card_bk-pending-01'),
        );
        expect(cardFinder, findsOneWidget);

        await tester.tap(cardFinder);
        await tester.pumpAndSettle();

        // Navigates to BookingTrackingScreen
        expect(find.text('Booking Details'), findsOneWidget);
        expect(find.text('ID: bk-pending-01'), findsOneWidget);
        expect(find.text('Service Progress'), findsOneWidget);
      },
    );

    testWidgets(
      'AC 6: Empty state message appears when there are no bookings in a tab',
      (tester) async {
        // Customer with only past bookings
        final onlyPastBooking = BookingModel(
          id: 'bk-past-only',
          customerId: 'customer-past',
          providerId: 'prov-1',
          providerName: 'Clean Co',
          serviceCategory: 'Cleaning',
          serviceTitle: 'Room Cleaning',
          description: 'Cleaning',
          address: 'Phnom Penh',
          preferredDateTime: DateTime(2026, 11, 10),
          status: BookingStatus.completed,
          createdAt: DateTime(2026, 11, 9),
        );

        final service = BookingService(
          initialBookings: [onlyPastBooking],
          customerId: 'customer-past',
        );

        await tester.pumpWidget(
          buildBookingHistoryTestApp(
            customService: service,
            activeCustomerId: 'customer-past',
          ),
        );
        await tester.pumpAndSettle();

        // Active tab has no active bookings
        expect(
          find.text('You have no active repair bookings right now.'),
          findsOneWidget,
        );

        // Switch to Past tab -> has the past booking
        await tester.tap(find.byKey(const Key('booking_history_tab_past')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('booking_history_card_bk-past-only')),
          findsOneWidget,
        );
        expect(
          find.text('You have no past repair booking history.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC 5: Tenant Data Isolation ensures customer cannot view another customers bookings',
      (tester) async {
        final service = BookingService();
        // Default customer is customer-1, bk-other-customer-99 belongs to other-customer-999
        await tester.pumpWidget(
          buildBookingHistoryTestApp(
            customService: service,
            activeCustomerId: 'customer-1',
          ),
        );
        await tester.pumpAndSettle();

        // Other customer's booking is excluded
        expect(
          find.byKey(const Key('booking_history_card_bk-other-customer-99')),
          findsNothing,
        );
      },
    );
  });
}
