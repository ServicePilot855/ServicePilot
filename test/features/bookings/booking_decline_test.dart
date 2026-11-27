import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/incoming_booking_request.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/services/firestore_booking_service.dart';

void main() {
  const customerId = 'customer-1';
  const ownerId = 'prov-virak-ac';
  const unrelatedProviderId = 'prov-unrelated-999';
  final now = DateTime(2026, 11, 26, 10, 0);

  BookingModel buildBooking({
    required String id,
    String providerId = ownerId,
    BookingStatus status = BookingStatus.pending,
  }) {
    return BookingModel(
      id: id,
      customerId: customerId,
      providerId: providerId,
      providerName: 'Virak Chan',
      serviceCategory: 'Air Conditioner Repair & Care',
      serviceTitle: 'Split AC Chemical Wash',
      description: 'AC unit dripping water indoors.',
      address: 'St. 310, BKK1, Phnom Penh',
      preferredDateTime: DateTime(2026, 11, 28, 14, 30),
      status: status,
      totalPrice: 25.0,
      createdAt: now,
    );
  }

  group('SCRUM-105 / BOOK-3: Decline a pending booking', () {
    test('the Firestore service declines when full booking reads are denied',
        () async {
      final firestore = FakeFirebaseFirestore(securityRules: '''
service cloud.firestore {
  match /databases/{database}/documents {
    match /bookings/{bookingId} {
      allow write: if true;
      allow read: if false;
    }
    match /providers/{providerId}/incomingBookingRequests/{bookingId} {
      allow read, write: if true;
    }
    match /providers/{providerId}/declinedBookingRequests/{bookingId} {
      allow read, write: if true;
    }
  }
}
''');
      final service = FirestoreBookingService(firestore: firestore);
      final booking = buildBooking(id: 'restricted-request');
      final privateRef = firestore.collection('bookings').doc(booking.id);
      final preview = IncomingBookingRequest.fromBooking(booking).toFirestore();
      final provider = firestore.collection('providers').doc(ownerId);
      final pending =
          provider.collection('incomingBookingRequests').doc(booking.id);
      final declined =
          provider.collection('declinedBookingRequests').doc(booking.id);
      await privateRef.set({
        ...booking.toFirestore(),
        'declinedReason': 'Pre-existing reason',
      });
      await pending.set(preview);

      await service.declineBooking(
        bookingId: booking.id,
        providerId: ownerId,
        reason: '   ',
      );

      expect((await pending.get()).exists, isFalse);
      expect((await declined.get()).data(), preview);
      final stored = jsonDecode(firestore.dump())['bookings'][booking.id] as Map;
      expect(stored['status'], 'declined');
      expect(stored.containsKey('declinedReason'), isFalse);
    });

    test(
        'owner declines a Pending request: status is Declined and reason is kept',
        () async {
      final service = BookingService(
        initialBookings: [buildBooking(id: 'bk-1')],
        customerId: customerId,
      );

      await service.declineBooking(
        bookingId: 'bk-1',
        providerId: ownerId,
        reason: '  Outside our service area that day  ',
      );

      final persisted = await service.getBookingById('bk-1');
      expect(persisted?.status, BookingStatus.declined);
      expect(persisted?.declinedReason, 'Outside our service area that day');
      expect(persisted?.updatedAt, isNotNull);
    });

    test(
        'declined record stays in the customer history and leaves the provider inbox',
        () async {
      final service = BookingService(
        initialBookings: [buildBooking(id: 'bk-2')],
        customerId: customerId,
      );
      expect(await service.getIncomingRequests(ownerId), hasLength(1));

      await service.declineBooking(
        bookingId: 'bk-2',
        providerId: ownerId,
        reason: 'Fully booked',
      );

      final history = await service.getCustomerBookings(customerId);
      expect(history.map((b) => b.id), contains('bk-2'));
      expect(
        history.firstWhere((b) => b.id == 'bk-2').status,
        BookingStatus.declined,
      );
      expect(await service.getIncomingRequests(ownerId), isEmpty);
      expect((await service.getDeclinedRequests(ownerId)).single.id, 'bk-2');
      expect(await service.getDeclinedRequests(unrelatedProviderId), isEmpty);
    });

    test(
        'an unrelated provider cannot decline the request and the record is unchanged',
        () async {
      final service = BookingService(
        initialBookings: [buildBooking(id: 'bk-3')],
        customerId: customerId,
      );

      await expectLater(
        service.declineBooking(
          bookingId: 'bk-3',
          providerId: unrelatedProviderId,
          reason: 'Not mine',
        ),
        throwsA(isA<UnauthorizedBookingDeclineException>()),
      );

      final unchanged = await service.getBookingById('bk-3');
      expect(unchanged?.status, BookingStatus.pending);
      expect(unchanged?.declinedReason, isNull);
    });

    for (final status in [
      BookingStatus.confirmed,
      BookingStatus.assigned,
      BookingStatus.inProgress,
      BookingStatus.completed,
      BookingStatus.cancelled,
      BookingStatus.declined,
    ]) {
      test('a ${status.value} booking cannot be declined', () async {
        final service = BookingService(
          initialBookings: [buildBooking(id: 'bk-state', status: status)],
          customerId: customerId,
        );

        await expectLater(
          service.declineBooking(
            bookingId: 'bk-state',
            providerId: ownerId,
            reason: 'Too late',
          ),
          throwsA(isA<InvalidBookingDeclineStateException>()),
        );

        final unchanged = await service.getBookingById('bk-state');
        expect(unchanged?.status, status);
      });
    }

    test('a declined request cannot be confirmed or started afterwards',
        () async {
      final service = BookingService(
        initialBookings: [buildBooking(id: 'bk-4')],
        customerId: customerId,
      );
      await service.declineBooking(
        bookingId: 'bk-4',
        providerId: ownerId,
        reason: 'Fully booked',
      );

      await expectLater(
        service.acceptBooking(bookingId: 'bk-4', providerId: ownerId),
        throwsA(isA<InvalidBookingTransitionException>()),
      );
      await expectLater(
        service.startBooking(bookingId: 'bk-4'),
        throwsA(isA<InvalidBookingTransitionException>()),
      );
    });

    test('a blank reason is stored as no reason', () async {
      final service = BookingService(
        initialBookings: [
          buildBooking(id: 'bk-5').copyWith(declinedReason: 'Pre-existing reason'),
        ],
        customerId: customerId,
      );

      await service.declineBooking(
        bookingId: 'bk-5',
        providerId: ownerId,
        reason: '   ',
      );

      final declined = await service.getBookingById('bk-5');
      expect(declined?.status, BookingStatus.declined);
      expect(declined?.declinedReason, isNull);
    });

    test('throws BookingNotFoundException for an unknown booking', () async {
      final service =
          BookingService(initialBookings: const [], customerId: customerId);

      await expectLater(
        service.declineBooking(bookingId: 'bk-missing', providerId: ownerId),
        throwsA(isA<BookingNotFoundException>()),
      );
    });
  });

  group('SCRUM-105 / BOOK-3: BookingModel decline eligibility', () {
    test('only the addressed provider can decline a Pending request', () {
      final pending = buildBooking(id: 'bk-model-1');
      expect(pending.canBeDeclinedBy(ownerId), isTrue);
      expect(pending.canBeDeclinedBy(unrelatedProviderId), isFalse);
    });

    test('non-pending requests cannot be declined by anyone', () {
      final confirmed = buildBooking(
        id: 'bk-model-2',
        status: BookingStatus.confirmed,
      );
      expect(confirmed.canBeDeclinedBy(ownerId), isFalse);
    });

    test('declinedReason survives Firestore round trip', () {
      final declined = buildBooking(id: 'bk-model-3').copyWith(
        status: BookingStatus.declined,
        declinedReason: 'Outside our area',
      );

      final restored = BookingModel.fromFirestore(
        declined.id,
        declined.toFirestore(),
      );

      expect(restored.status, BookingStatus.declined);
      expect(restored.declinedReason, 'Outside our area');
    });
  });
}
