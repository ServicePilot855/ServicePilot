import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/services/booking_photo_uploader.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/services/firestore_booking_service.dart';

/// Records uploads instead of talking to Firebase Storage.
class _FakeUploader implements IBookingPhotoUploader {
  _FakeUploader({this.fail = false});

  final bool fail;
  final uploads = <String>[];

  @override
  Future<List<String>> upload({
    required String customerId,
    required String bookingId,
    required List<BookingPhoto> photos,
  }) async {
    if (fail) {
      throw FirebaseException(plugin: 'firebase_storage', code: 'unauthorized');
    }
    return [
      for (final photo in photos)
        (uploads..add('bookings/$customerId/$bookingId/${photo.name}')).last,
    ].map((path) => 'https://storage.test/$path').toList();
  }
}

BookingPhoto _photo(String name) =>
    BookingPhoto(bytes: Uint8List.fromList([1, 2, 3]), name: name);

BookingRequest _request({
  String customerId = 'customer-1',
  String description = '  Kitchen sink pipe leaks when the pump runs.  ',
  DateTime? when,
  List<BookingPhoto> photos = const [],
  double? latitude,
  double? longitude,
}) {
  return BookingRequest(
    customerId: customerId,
    providerId: 'prov-plumb-01',
    providerName: 'Mekong Pipe & Drainage',
    serviceCategory: 'Plumbing',
    serviceTitle: 'Leak Repair',
    description: description,
    address: 'St. 592, Boeung Kak 2, Toul Kork',
    preferredDateTime: when ?? DateTime.now().add(const Duration(days: 2)),
    estimatedPrice: 18,
    photos: photos,
    latitude: latitude,
    longitude: longitude,
  );
}

void main() {
  group('SCRUM-43 / US-12: BookingService.createBooking (in memory)', () {
    test('saves a Pending booking for the customer and provider', () async {
      final service = BookingService(initialBookings: []);
      final booking = await service.createBooking(_request());

      expect(booking.status, BookingStatus.pending);
      expect(booking.customerId, 'customer-1');
      expect(booking.providerId, 'prov-plumb-01');
      expect(booking.description,
          'Kitchen sink pipe leaks when the pump runs.');
      expect(booking.totalPrice, 18);

      expect(await service.getBookingById(booking.id), isNotNull);
      expect(await service.getCustomerBookings('customer-1'), hasLength(1));
      expect(await service.getCustomerBookings('someone-else'), isEmpty);
    });

    test('rejects a request that breaks the field rules', () async {
      final service = BookingService(initialBookings: []);
      await expectLater(
        service.createBooking(_request(
          description: 'leak',
          when: DateTime.now().subtract(const Duration(days: 1)),
        )),
        throwsA(
          isA<InvalidBookingRequestException>().having(
            (e) => e.errors,
            'errors',
            [
              BookingFieldError.descriptionTooShort,
              BookingFieldError.dateTimeTooSoon,
            ],
          ),
        ),
      );
      expect(await service.getCustomerBookings('customer-1'), isEmpty);
    });
  });

  group('SCRUM-43 / US-12: FirestoreBookingService', () {
    late FakeFirebaseFirestore firestore;
    late _FakeUploader uploader;
    late FirestoreBookingService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      uploader = _FakeUploader();
      service = FirestoreBookingService(
        firestore: firestore,
        photoUploader: uploader,
      );
    });

    test('uploads photos into the customer\'s folder and saves their links',
        () async {
      final booking = await service.createBooking(
        _request(photos: [_photo('sink.jpg'), _photo('pipe.jpg')]),
      );

      expect(uploader.uploads, [
        'bookings/customer-1/${booking.id}/sink.jpg',
        'bookings/customer-1/${booking.id}/pipe.jpg',
      ]);
      final data =
          (await firestore.collection('bookings').doc(booking.id).get())
              .data()!;
      expect(data['photos'], hasLength(2));
      expect(booking.photoUrls, data['photos']);
    });

    test('no booking is written when the photo upload fails', () async {
      final failing = FirestoreBookingService(
        firestore: firestore,
        photoUploader: _FakeUploader(fail: true),
      );
      await expectLater(
        failing.createBooking(_request(photos: [_photo('sink.jpg')])),
        throwsA(isA<BookingSubmissionException>()),
      );
      expect((await firestore.collection('bookings').get()).docs, isEmpty);
    });

    test('saves the map pin as a GeoPoint and reads it back', () async {
      final booking = await service.createBooking(
        _request(latitude: 11.5564, longitude: 104.9282),
      );
      final data =
          (await firestore.collection('bookings').doc(booking.id).get())
              .data()!;
      expect(data['location'], const GeoPoint(11.5564, 104.9282));

      final loaded = await service.getBookingById(booking.id);
      expect(loaded!.latitude, 11.5564);
      expect(loaded.longitude, 104.9282);
    });

    test('a booking without pin or photos stores neither field', () async {
      final booking = await service.createBooking(_request());
      final data =
          (await firestore.collection('bookings').doc(booking.id).get())
              .data()!;
      expect(data.containsKey('location'), isFalse);
      expect(data.containsKey('photos'), isFalse);
      expect(uploader.uploads, isEmpty);
    });

    test('writes a Pending booking to the bookings collection', () async {
      final booking = await service.createBooking(_request());

      final doc = await firestore.collection('bookings').doc(booking.id).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['status'], 'pending');
      expect(data['customerId'], 'customer-1');
      expect(data['providerId'], 'prov-plumb-01');
      expect(data['id'], booking.id);
    });

    test('publishes only scheduling and job details in the provider inbox',
        () async {
      final booking = await service.createBooking(
        _request(photos: [_photo('sink.jpg')], latitude: 11.5, longitude: 104.9),
      );
      final preview = await firestore
          .doc('providers/prov-plumb-01/incomingBookingRequests/${booking.id}')
          .get();

      expect(preview.data(), {
        'serviceTitle': 'Leak Repair',
        'description': booking.description,
        'appointmentDate': Timestamp.fromDate(booking.preferredDateTime),
      });
    });

    test('uses the field names firestore.rules accepts', () async {
      final booking = await service.createBooking(_request());
      final data =
          (await firestore.collection('bookings').doc(booking.id).get())
              .data()!;

      expect(data['categoryName'], 'Plumbing');
      expect(data['serviceType'], 'Leak Repair');
      expect(data['appointmentDate'], isA<Timestamp>());
      expect(data['createdAt'], isA<Timestamp>());
      for (final key in ['serviceCategory', 'serviceTitle', 'preferredDateTime']) {
        expect(data.containsKey(key), isFalse, reason: '$key is not allowed');
      }
    });

    test('a saved booking reads back unchanged', () async {
      final created = await service.createBooking(_request());
      final loaded = await service.getBookingById(created.id);

      expect(loaded, isNotNull);
      expect(loaded!.serviceTitle, created.serviceTitle);
      expect(loaded.serviceCategory, created.serviceCategory);
      expect(loaded.address, created.address);
      expect(loaded.preferredDateTime, created.preferredDateTime);
      expect(loaded.status, BookingStatus.pending);
    });

    test('the existing confirmation API removes the request from the inbox', () async {
      final created = await service.createBooking(_request());
      await service.acceptBooking(
        bookingId: created.id,
        providerId: created.providerId,
      );

      final confirmed = await service.getBookingById(created.id);
      expect(confirmed?.status, BookingStatus.confirmed);
      expect(confirmed?.confirmedAppointmentAt, created.preferredDateTime);
      expect(confirmed?.confirmedBy, created.providerId);
      expect(await service.getIncomingRequest(created.providerId, created.id), isNull);
    });

    test('customers only get their own bookings', () async {
      await service.createBooking(_request());
      await service.createBooking(_request(customerId: 'customer-2'));

      final mine = await service.getCustomerBookings('customer-1');
      expect(mine, hasLength(1));
      expect(mine.single.customerId, 'customer-1');
    });

    test('invalid requests are not written', () async {
      await expectLater(
        service.createBooking(_request(description: '')),
        throwsA(isA<InvalidBookingRequestException>()),
      );
      expect((await firestore.collection('bookings').get()).docs, isEmpty);
    });

    test('a created booking can be cancelled by its customer (US-14)',
        () async {
      final created = await service.createBooking(_request());
      final cancelled = await service.cancelBooking(
        bookingId: created.id,
        customerId: 'customer-1',
        reason: 'Fixed it myself',
      );

      expect(cancelled.status, BookingStatus.cancelled);
      final data =
          (await firestore.collection('bookings').doc(created.id).get())
              .data()!;
      expect(data['status'], 'cancelled');
      expect(data['cancelledBy'], 'customer-1');
      expect(data['cancellationReason'], 'Fixed it myself');
      final inbox = await firestore
          .collection('providers/prov-plumb-01/incomingBookingRequests')
          .get();
      expect(inbox.docs, isEmpty);
    });

    test('another customer cannot cancel it', () async {
      final created = await service.createBooking(_request());
      await expectLater(
        service.cancelBooking(bookingId: created.id, customerId: 'intruder'),
        throwsA(isA<UnauthorizedBookingCancellationException>()),
      );
    });
  });
}
