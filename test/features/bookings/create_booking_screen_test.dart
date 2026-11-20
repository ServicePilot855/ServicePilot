import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/screens/booking_confirmation_screen.dart';
import 'package:service_pilot/features/bookings/screens/create_booking_screen.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/services/photo_source.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

const _provider = ProviderModel(
  id: 'prov-dara-ac',
  name: 'Dara Chhum',
  specialties: ['Chemical Coil Wash', 'Refrigerant Refill'],
  categoryIds: ['cat-ac'],
  hourlyRate: 20,
);

/// 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Hands back [count] photos per pick, honouring the form's limit.
class _FakePhotoSource implements IPhotoSource {
  _FakePhotoSource({this.count = 2, this.size});

  final int count;
  final int? size;
  final requestedLimits = <int>[];

  @override
  Future<List<BookingPhoto>> pick(PhotoOrigin origin, {required int limit}) async {
    requestedLimits.add(limit);
    return [
      for (var i = 0; i < count && i < limit; i++)
        BookingPhoto(
          bytes: size == null ? _png : Uint8List(size!),
          name: 'photo_$i.png',
          contentType: 'image/png',
        ),
    ];
  }
}

void main() {
  late BookingService service;
  late _FakePhotoSource photoSource;

  setUp(() {
    service = BookingService(initialBookings: []);
    photoSource = _FakePhotoSource();
  });

  Widget app({ProviderModel provider = _provider}) {
    final router = GoRouter(
      initialLocation: '/providers/${provider.id}/book',
      routes: [
        GoRoute(
          path: '/providers/:providerId/book',
          builder: (_, state) => CreateBookingScreen(
            providerId: state.pathParameters['providerId']!,
            initialProvider: provider,
          ),
        ),
        // Stands in for the OpenStreetMap screen (no tiles in tests).
        GoRoute(
          path: '/providers/:providerId/book/location',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  context.pop(const LatLng(11.5564, 104.9282)),
              child: const Text('pick test location'),
            ),
          ),
        ),
        GoRoute(
          path: '/bookings/:bookingId/sent',
          builder: (_, state) => BookingConfirmationScreen(
            bookingId: state.pathParameters['bookingId']!,
            booking: state.extra as BookingModel?,
          ),
        ),
        GoRoute(
          path: '/bookings/:bookingId',
          builder: (_, state) =>
              Text('tracking ${state.pathParameters['bookingId']}'),
        ),
        GoRoute(
          path: '/home/customer',
          builder: (_, __) => const Text('customer home'),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        activeCustomerIdProvider.overrideWithValue('customer-1'),
        bookingServiceProvider.overrideWithValue(service),
        photoSourceProvider.overrideWithValue(photoSource),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Opens both pickers and accepts their defaults: tomorrow at 9:00.
  Future<void> pickTomorrowAtNine(WidgetTester tester) async {
    await tapVisible(tester, find.byKey(const Key('booking_date_picker')));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('booking_time_picker')));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  group('SCRUM-43 / US-12: CreateBookingScreen', () {
    testWidgets('shows the provider services to choose from', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('Request a repair'), findsOneWidget);
      expect(find.text('Chemical Coil Wash'), findsOneWidget);
      expect(find.text('Refrigerant Refill'), findsOneWidget);
      expect(find.text('From \$20.00'), findsOneWidget);
    });

    testWidgets('sending an empty form shows an error under every field',
        (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('booking_submit_button')));

      expect(find.text('Choose the service you need.'), findsOneWidget);
      expect(
        find.text('Describe the problem so the provider knows what to expect.'),
        findsOneWidget,
      );
      expect(find.text('Enter the address where the repair is needed.'),
          findsOneWidget);
      expect(find.text('Choose a date and a time.'), findsOneWidget);
      expect(await service.getCustomerBookings('customer-1'), isEmpty);
    });

    testWidgets('too-short details get a specific message', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('booking_description_field')), 'AC bad');
      await tester.enterText(
          find.byKey(const Key('booking_address_field')), 'BKK1');
      await tapVisible(tester, find.byKey(const Key('booking_submit_button')));

      expect(find.text('Add a little more detail (at least 15 characters).'),
          findsOneWidget);
      expect(find.text('Add your street and khan so the technician can find you.'),
          findsWidgets);
    });

    testWidgets(
        'a complete request is saved as Pending and shows the confirmation',
        (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tapVisible(
          tester, find.byKey(const Key('booking_service_Chemical Coil Wash')));
      await tester.enterText(
        find.byKey(const Key('booking_description_field')),
        'Bedroom AC blows warm air and drips water.',
      );
      await tester.enterText(
        find.byKey(const Key('booking_address_field')),
        'St. 310, BKK1, Chamkarmon',
      );
      await pickTomorrowAtNine(tester);
      await tapVisible(tester, find.byKey(const Key('booking_submit_button')));

      // Saved for this customer and directed to the chosen provider.
      final saved = await service.getCustomerBookings('customer-1');
      expect(saved, hasLength(1));
      final booking = saved.single;
      expect(booking.status, BookingStatus.pending);
      expect(booking.providerId, 'prov-dara-ac');
      expect(booking.serviceTitle, 'Chemical Coil Wash');
      expect(booking.address, 'St. 310, BKK1, Chamkarmon');
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(booking.preferredDateTime,
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9));

      // Confirmation, then on to booking status.
      expect(find.byKey(const Key('booking_request_sent_hero')), findsOneWidget);
      expect(find.text('Request sent'), findsOneWidget);
      await tapVisible(
          tester, find.byKey(const Key('booking_view_status_button')));
      expect(find.text('tracking ${booking.id}'), findsOneWidget);
    });

    testWidgets('photos and a map pin are sent with the request',
        (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Two photos from the gallery, then remove the first.
      await tapVisible(tester, find.byKey(const Key('booking_add_photo')));
      await tester.tap(find.byKey(const Key('booking_photo_gallery')));
      await tester.pumpAndSettle();
      expect(photoSource.requestedLimits, [5]);
      expect(find.byKey(const Key('booking_photo_0')), findsOneWidget);
      expect(find.byKey(const Key('booking_photo_1')), findsOneWidget);

      await tapVisible(
          tester, find.byKey(const Key('booking_photo_remove_0')));
      expect(find.byKey(const Key('booking_photo_1')), findsNothing);

      // Pin the address.
      await tapVisible(tester, find.byKey(const Key('booking_pin_location')));
      await tester.tap(find.text('pick test location'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booking_location_pinned')), findsOneWidget);
      expect(find.text('11.55640, 104.92820'), findsOneWidget);

      // Fill in the rest and send.
      await tapVisible(
          tester, find.byKey(const Key('booking_service_Chemical Coil Wash')));
      await tester.enterText(
        find.byKey(const Key('booking_description_field')),
        'Bedroom AC blows warm air and drips water.',
      );
      await tester.enterText(
        find.byKey(const Key('booking_address_field')),
        'St. 310, BKK1, Chamkarmon',
      );
      await pickTomorrowAtNine(tester);
      await tapVisible(tester, find.byKey(const Key('booking_submit_button')));

      final booking = (await service.getCustomerBookings('customer-1')).single;
      expect(booking.latitude, 11.5564);
      expect(booking.longitude, 104.9282);
      expect(booking.photoUrls, hasLength(1));
      expect(find.text('1 photo attached'), findsOneWidget);
    });

    testWidgets('photos over 5 MB are refused with a message', (tester) async {
      photoSource = _FakePhotoSource(count: 1, size: 5 * 1024 * 1024 + 1);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('booking_add_photo')));
      await tester.tap(find.byKey(const Key('booking_photo_camera')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('booking_photo_0')), findsNothing);
      expect(
        find.text('Each photo must be 5 MB or smaller. Choose a smaller photo.'),
        findsOneWidget,
      );
    });

    testWidgets('a provider that is not taking bookings cannot be booked',
        (tester) async {
      await tester.pumpWidget(app(
        provider: _provider.copyWith(isAvailable: false),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('booking_provider_unavailable')),
          findsOneWidget);
      expect(find.byKey(const Key('booking_submit_button')), findsNothing);
    });
  });
}
