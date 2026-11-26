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
import 'package:service_pilot/features/bookings/services/booking_service.dart';
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

  BookingModel pendingBooking(String id) => BookingModel(
        id: id,
        customerId: customerUser.id,
        providerId: providerUser.id,
        providerName: 'Virak Chan',
        serviceCategory: 'Air Conditioner Repair & Care',
        serviceTitle: 'Split AC Chemical Wash',
        description: 'AC unit dripping water indoors.',
        address: 'St. 310, BKK1, Phnom Penh',
        preferredDateTime: DateTime(2026, 11, 28, 14, 30),
        status: BookingStatus.pending,
        totalPrice: 25.0,
        createdAt: now,
      );

  void setupViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget providerApp(BookingService service, {required String bookingId}) {
    return ProviderScope(
      overrides: [
        bookingServiceProvider.overrideWithValue(service),
        authProvider.overrideWith(() => _MockAuthNotifier(providerUser)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProviderBookingDetailScreen(bookingId: bookingId),
      ),
    );
  }

  group('SCRUM-105 / BOOK-3: Provider decline flow', () {
    testWidgets(
      'provider declines a Pending request with a reason; both views show Declined and the request leaves the inbox',
      (tester) async {
        setupViewport(tester);
        final service = BookingService(
          initialBookings: [pendingBooking('bk-decline-1')],
          customerId: customerUser.id,
        );
        addTearDown(service.dispose);

        await tester.pumpWidget(providerApp(service, bookingId: 'bk-decline-1'));
        await tester.pumpAndSettle();

        final declineBtn =
            find.byKey(const Key('provider_decline_booking_button'));
        expect(declineBtn, findsOneWidget);
        await tester.tap(declineBtn);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('decline_booking_dialog')), findsOneWidget);
        final confirm = find.byKey(const Key('decline_dialog_confirm_button'));
        expect(confirm, findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('decline_reason_field')),
          'Outside our service area that day',
        );
        await tester.pumpAndSettle();
        await tester.tap(confirm);
        await tester.pumpAndSettle();

        // Provider view: Declined state, no decision actions left.
        expect(
          find.byKey(const Key('provider_booking_declined_notice')),
          findsOneWidget,
        );
        expect(find.text('Declined'), findsWidgets);
        expect(
          find.byKey(const Key('provider_confirm_booking_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('provider_decline_booking_button')),
          findsNothing,
        );

        // Persisted state and inbox.
        final stored = await service.getBookingById('bk-decline-1');
        expect(stored?.status, BookingStatus.declined);
        expect(stored?.declinedReason, 'Outside our service area that day');
        expect(await service.getIncomingRequests(providerUser.id), isEmpty);

        // Customer view: the same booking shows Declined.
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
              home: const BookingTrackingScreen(bookingId: 'bk-decline-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Declined'), findsWidgets);
        expect(find.byKey(const Key('cancel_booking_button')), findsNothing);
      },
    );

    testWidgets(
      'Decline needs a reason: confirm stays disabled until text is entered',
      (tester) async {
        setupViewport(tester);
        final service = BookingService(
          initialBookings: [pendingBooking('bk-decline-2')],
          customerId: customerUser.id,
        );
        addTearDown(service.dispose);

        await tester.pumpWidget(providerApp(service, bookingId: 'bk-decline-2'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('provider_decline_booking_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('decline_reason_required_hint')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('decline_dialog_confirm_button')));
        await tester.pumpAndSettle();

        // Still open: nothing was declined.
        expect(find.byKey(const Key('decline_booking_dialog')), findsOneWidget);
        expect(
          (await service.getBookingById('bk-decline-2'))?.status,
          BookingStatus.pending,
        );
      },
    );

    testWidgets(
      'Keep Request closes the dialog and leaves the booking Pending',
      (tester) async {
        setupViewport(tester);
        final service = BookingService(
          initialBookings: [pendingBooking('bk-decline-3')],
          customerId: customerUser.id,
        );
        addTearDown(service.dispose);

        await tester.pumpWidget(providerApp(service, bookingId: 'bk-decline-3'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('provider_decline_booking_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('decline_dialog_keep_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('decline_booking_dialog')), findsNothing);
        expect(
          find.byKey(const Key('provider_confirm_booking_button')),
          findsOneWidget,
        );
        expect(
          (await service.getBookingById('bk-decline-3'))?.status,
          BookingStatus.pending,
        );
      },
    );
  });
}
