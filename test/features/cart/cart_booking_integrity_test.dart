import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_item.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/services/booking_photo_uploader.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/services/firestore_booking_service.dart';

/// CART-3 (SCRUM-82) verification, subtasks SCRUM-131 and SCRUM-133: a valid
/// cart produces one Pending booking with the same provider, items and total;
/// invalid inputs or mixed-provider items produce no booking.

class _NoUploads implements IBookingPhotoUploader {
  @override
  Future<List<String>> upload({
    required String customerId,
    required String bookingId,
    required List<BookingPhoto> photos,
  }) async =>
      const [];
}

const _acWash = BookingItem(
  offeringId: 'off-a1',
  providerId: 'prov-a',
  title: 'Split AC Wash',
  unitPrice: 25,
  quantity: 2,
);

const _gasTopUp = BookingItem(
  offeringId: 'off-a2',
  providerId: 'prov-a',
  title: 'Gas Top-up',
  unitPrice: 35.1,
);

const _otherProviderItem = BookingItem(
  offeringId: 'off-b1',
  providerId: 'prov-b',
  title: 'Tap Replacement',
  unitPrice: 20,
);

BookingRequest _cartRequest({
  List<BookingItem> items = const [_acWash, _gasTopUp],
  String description = 'Both units drip water and blow warm air.',
  DateTime? when,
}) {
  return BookingRequest(
    customerId: 'homeowner-a',
    providerId: 'prov-a',
    providerName: 'Dara Technician',
    serviceCategory: 'Air Conditioning',
    serviceTitle: BookingRequest.cartServiceTitle(items),
    description: description,
    address: 'St. 271, Toul Tom Poung, Chamkarmon',
    preferredDateTime: when ?? DateTime.now().add(const Duration(days: 1)),
    // A stale estimate must not decide the saved total.
    estimatedPrice: 999,
    items: items,
  );
}

void main() {
  group('SCRUM-131 / SCRUM-133: cart request rules', () {
    test('the total is the sum of the lines, in cents', () {
      expect(BookingItem.totalOf(const [_acWash, _gasTopUp]), 85.1);
      expect(_cartRequest().totalPrice, 85.1);
      expect(_cartRequest().isFromCart, isTrue);
    });

    test('a valid cart has no errors', () {
      expect(BookingRequestValidator.validate(_cartRequest()), isEmpty);
    });

    test('an item from another provider is a mixed-provider error', () {
      expect(
        BookingRequestValidator.validate(
          _cartRequest(items: const [_acWash, _otherProviderItem]),
        ),
        contains(BookingFieldError.cartMixedProviders),
      );
    });

    test('broken lines are rejected', () {
      const broken = [
        BookingItem(
            offeringId: '', providerId: 'prov-a', title: 'X', unitPrice: 5),
        BookingItem(
            offeringId: 'o', providerId: 'prov-a', title: ' ', unitPrice: 5),
        BookingItem(
            offeringId: 'o', providerId: 'prov-a', title: 'X', unitPrice: 0),
        BookingItem(
            offeringId: 'o',
            providerId: 'prov-a',
            title: 'X',
            unitPrice: 5,
            quantity: 0),
      ];
      for (final item in broken) {
        expect(
          BookingRequestValidator.cartItems([item], providerId: 'prov-a'),
          BookingFieldError.cartItemsInvalid,
          reason: item.toMap().toString(),
        );
      }
      expect(
        BookingRequestValidator.cartItems(
          const [_acWash, _acWash],
          providerId: 'prov-a',
        ),
        BookingFieldError.cartItemsInvalid,
        reason: 'the same offering twice',
      );
      expect(
        BookingRequestValidator.cartItems(
          [
            for (var i = 0; i <= BookingRequestValidator.maxCartItems; i++)
              BookingItem(
                offeringId: 'o$i',
                providerId: 'prov-a',
                title: 'Service $i',
                unitPrice: 5,
              ),
          ],
          providerId: 'prov-a',
        ),
        BookingFieldError.cartItemsInvalid,
        reason: 'more lines than Firestore accepts',
      );
    });

    test('a long cart title is shortened to what Firestore accepts', () {
      final items = [
        for (var i = 0; i < 8; i++)
          BookingItem(
            offeringId: 'o$i',
            providerId: 'prov-a',
            title: 'Deep chemical wash for unit $i',
            unitPrice: 5,
          ),
      ];
      final title = BookingRequest.cartServiceTitle(items);
      expect(title.length, BookingRequest.serviceTitleMaxLength);
      expect(title, endsWith('…'));
      expect(
        BookingRequest.cartServiceTitle(const [_acWash, _gasTopUp]),
        'Split AC Wash, Gas Top-up',
      );
    });
  });

  group('SCRUM-131 / SCRUM-133: BookingService (in memory)', () {
    test('a valid cart saves one Pending booking with its items and total',
        () async {
      final service = BookingService(initialBookings: []);
      final booking = await service.createBooking(_cartRequest());

      expect(booking.status, BookingStatus.pending);
      expect(booking.customerId, 'homeowner-a');
      expect(booking.providerId, 'prov-a');
      expect(booking.totalPrice, 85.1);
      expect(booking.serviceTitle, 'Split AC Wash, Gas Top-up');
      expect(booking.items.map((i) => i.offeringId), ['off-a1', 'off-a2']);
      expect(booking.items.first.quantity, 2);
      expect(await service.getCustomerBookings('homeowner-a'), hasLength(1));
    });

    test('mixed-provider items save no booking', () async {
      final service = BookingService(initialBookings: []);
      await expectLater(
        service.createBooking(
          _cartRequest(items: const [_acWash, _otherProviderItem]),
        ),
        throwsA(isA<InvalidBookingRequestException>().having(
          (e) => e.errors,
          'errors',
          contains(BookingFieldError.cartMixedProviders),
        )),
      );
      expect(await service.getCustomerBookings('homeowner-a'), isEmpty);
    });

    test('invalid job details save no booking', () async {
      final service = BookingService(initialBookings: []);
      await expectLater(
        service.createBooking(_cartRequest(
          description: 'drips',
          when: DateTime.now().subtract(const Duration(hours: 1)),
        )),
        throwsA(isA<InvalidBookingRequestException>()),
      );
      expect(await service.getCustomerBookings('homeowner-a'), isEmpty);
    });
  });

  group('SCRUM-131 / SCRUM-133: FirestoreBookingService', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreBookingService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FirestoreBookingService(
        firestore: firestore,
        photoUploader: _NoUploads(),
      );
    });

    test('writes the cart lines to `services` with the computed total',
        () async {
      final booking = await service.createBooking(_cartRequest());

      final data =
          (await firestore.collection('bookings').doc(booking.id).get())
              .data()!;
      expect(data['status'], 'pending');
      expect(data['customerId'], 'homeowner-a');
      expect(data['providerId'], 'prov-a');
      expect(data['totalPrice'], 85.1);
      expect(data['services'], [
        {
          'offeringId': 'off-a1',
          'title': 'Split AC Wash',
          'unitPrice': 25.0,
          'quantity': 2,
        },
        {
          'offeringId': 'off-a2',
          'title': 'Gas Top-up',
          'unitPrice': 35.1,
          'quantity': 1,
        },
      ]);
      expect(data.containsKey('items'), isFalse,
          reason: 'firestore.rules only accepts `services`');

      final reread = BookingModel.fromFirestore(booking.id, data);
      expect(reread.items.map((i) => i.title), ['Split AC Wash', 'Gas Top-up']);
      expect(reread.items.every((i) => i.providerId == 'prov-a'), isTrue);
      expect(BookingItem.totalOf(reread.items), reread.totalPrice);
    });

    test('mixed-provider items write nothing', () async {
      await expectLater(
        service.createBooking(
          _cartRequest(items: const [_acWash, _otherProviderItem]),
        ),
        throwsA(isA<InvalidBookingRequestException>()),
      );
      expect((await firestore.collection('bookings').get()).docs, isEmpty);
      expect(
        (await firestore
                .collection('providers/prov-a/incomingBookingRequests')
                .get())
            .docs,
        isEmpty,
      );
    });

    test('a single-service request still saves without `services`', () async {
      final booking = await service.createBooking(BookingRequest(
        customerId: 'homeowner-a',
        providerId: 'prov-a',
        providerName: 'Dara Technician',
        serviceCategory: 'Air Conditioning',
        serviceTitle: 'Split AC Wash',
        description: 'Both units drip water and blow warm air.',
        address: 'St. 271, Toul Tom Poung, Chamkarmon',
        preferredDateTime: DateTime.now().add(const Duration(days: 1)),
        estimatedPrice: 20,
      ));
      final data =
          (await firestore.collection('bookings').doc(booking.id).get())
              .data()!;
      expect(data.containsKey('services'), isFalse);
      expect(data['totalPrice'], 20);
    });
  });
}
