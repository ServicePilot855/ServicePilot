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
import 'package:service_pilot/features/bookings/screens/booking_tracking_screen.dart';
import 'package:service_pilot/features/bookings/screens/provider_booking_detail_screen.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/widgets/provider_booking_list.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

class _MockAuthNotifier extends AuthNotifier {
  final UserModel _user;
  _MockAuthNotifier(this._user);

  @override
  AuthState build() => AuthStateAuthenticated(_user);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 26, 10, 0);
  final preferredTime = DateTime(2026, 11, 28, 14, 30);

  const providerUser = UserModel(
    id: 'prov-virak-ac',
    fullName: 'Virak Chan',
    email: 'technician@test.com',
    phoneNumber: '+85512345678',
    role: AppRole.independentProvider,
    status: 'active',
  );

  const customerUser = UserModel(
    id: 'customer-1',
    fullName: 'Sokha Homeowner',
    email: 'customer@test.com',
    phoneNumber: '+85599887766',
    role: AppRole.homeowner,
    status: 'active',
  );

  BookingModel buildBooking({
    required String id,
    required String providerId,
    BookingStatus status = BookingStatus.pending,
    DateTime? confirmedAppointmentAt,
  }) {
    return BookingModel(
      id: id,
      customerId: customerUser.id,
      providerId: providerId,
      providerName: 'Virak Chan',
      serviceCategory: 'Air Conditioner Repair & Care',
      serviceTitle: 'Split AC Chemical Wash',
      description: 'AC unit dripping water indoors.',
      address: 'St. 310, BKK1, Phnom Penh',
      preferredDateTime: preferredTime,
      status: status,
      totalPrice: 25.0,
      createdAt: now,
      confirmedAppointmentAt: confirmedAppointmentAt,
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

  group('SCRUM-104 / BOOK-2: Provider & Customer Confirmation Views', () {
    testWidgets(
      'Provider confirms an owned Pending booking and both provider and customer views display Confirmed status and agreed time',
      (tester) async {
        setupViewport(tester);
        final booking = buildBooking(
          id: 'bk-confirm-test-1',
          providerId: 'prov-virak-ac',
        );
        final service = BookingService(
          initialBookings: [booking],
          customerId: customerUser.id,
        );

        final router = GoRouter(
          initialLocation: '/provider-home',
          routes: [
            GoRoute(
              path: '/provider-home',
              builder: (_, __) => const Scaffold(
                body: SingleChildScrollView(
                  child: ProviderBookingList(providerId: 'prov-virak-ac'),
                ),
              ),
            ),
            GoRoute(
              path: '/provider/bookings/:bookingId',
              builder: (_, state) => ProviderBookingDetailScreen(
                bookingId: state.pathParameters['bookingId'] ?? '',
                initialBooking: state.extra as BookingModel?,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bookingServiceProvider.overrideWithValue(service),
              authProvider.overrideWith(() => _MockAuthNotifier(providerUser)),
            ],
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Provider sees the incoming Pending booking
        expect(
          find.byKey(const Key('provider_booking_card_bk-confirm-test-1')),
          findsOneWidget,
        );
        expect(find.text('Split AC Chemical Wash'), findsOneWidget);

        // Tap Review to open ProviderBookingDetailScreen
        await tester.tap(
          find.byKey(const Key('provider_booking_review_bk-confirm-test-1')),
        );
        await tester.pumpAndSettle();

        // Confirm button is visible on eligible Pending booking
        final confirmBtn =
            find.byKey(const Key('provider_confirm_booking_button'));
        expect(confirmBtn, findsOneWidget);

        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Provider view shows success notice, Confirmed status, and confirmed time
        expect(
          find.byKey(const Key('provider_booking_confirmed_notice')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('provider_confirmed_appointment_row')),
          findsOneWidget,
        );
        expect(find.text('Confirmed'), findsWidgets);

        final formattedAgreed =
            DateFormat('EEE, d MMM yyyy • h:mm a').format(preferredTime);
        expect(find.text(formattedAgreed), findsWidgets);

        // Verify persisted state in service
        final updated = await service.getBookingById('bk-confirm-test-1');
        expect(updated?.status, equals(BookingStatus.confirmed));
        expect(updated?.confirmedAppointmentAt, equals(preferredTime));

        // Now render the Customer view (BookingTrackingScreen) for the same booking
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bookingServiceProvider.overrideWithValue(service),
              authProvider.overrideWith(() => _MockAuthNotifier(customerUser)),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const BookingTrackingScreen(bookingId: 'bk-confirm-test-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Customer view shows Confirmed status and confirmed appointment time
        expect(find.text('Confirmed'), findsWidgets);
        expect(
          find.byKey(const Key('booking_confirmed_appointment_row')),
          findsOneWidget,
        );
        expect(find.text(formattedAgreed), findsWidgets);
      },
    );

    testWidgets(
      'Ineligible booking (Cancelled) cannot be confirmed in provider view',
      (tester) async {
        setupViewport(tester);
        final cancelledBooking = buildBooking(
          id: 'bk-cancelled-1',
          providerId: 'prov-virak-ac',
          status: BookingStatus.cancelled,
        );
        final service = BookingService(
          initialBookings: [cancelledBooking],
          customerId: customerUser.id,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bookingServiceProvider.overrideWithValue(service),
              authProvider.overrideWith(() => _MockAuthNotifier(providerUser)),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: ProviderBookingDetailScreen(
                bookingId: cancelledBooking.id,
                initialBooking: cancelledBooking,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('provider_confirm_booking_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('provider_booking_ineligible_notice')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Another provider cannot confirm a booking they do not own',
      (tester) async {
        setupViewport(tester);
        final otherProvidersBooking = buildBooking(
          id: 'bk-other-prov-1',
          providerId: 'prov-fixco-company',
          status: BookingStatus.pending,
        );
        final service = BookingService(
          initialBookings: [otherProvidersBooking],
          customerId: customerUser.id,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bookingServiceProvider.overrideWithValue(service),
              authProvider.overrideWith(() => _MockAuthNotifier(providerUser)),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: ProviderBookingDetailScreen(
                bookingId: otherProvidersBooking.id,
                initialBooking: otherProvidersBooking,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('provider_confirm_booking_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('provider_booking_unauthorized_notice')),
          findsOneWidget,
        );
      },
    );
  });
}
