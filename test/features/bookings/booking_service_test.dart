import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';

void main() {
  group('SCRUM-45 / US-14: BookingService Cancellation Unit Tests', () {
    late BookingService bookingService;
    const customerId = BookingService.defaultCustomerId;

    setUp(() {
      bookingService = BookingService(customerId: customerId);
    });

    test('customer can cancel a booking with Pending status', () async {
      final result = await bookingService.cancelBooking(
        bookingId: 'bk-pending-01',
        customerId: customerId,
        reason: 'Found another schedule',
      );

      expect(result.status, equals(BookingStatus.cancelled));
      expect(result.cancelledBy, equals(customerId));
      expect(result.cancelledAt, isNotNull);
      expect(result.cancellationReason, equals('Found another schedule'));

      final persisted = await bookingService.getBookingById('bk-pending-01');
      expect(persisted?.status, equals(BookingStatus.cancelled));
    });

    test('customer can cancel a booking with Assigned status', () async {
      final result = await bookingService.cancelBooking(
        bookingId: 'bk-assigned-02',
        customerId: customerId,
      );

      expect(result.status, equals(BookingStatus.cancelled));
      expect(result.cancelledBy, equals(customerId));

      final persisted = await bookingService.getBookingById('bk-assigned-02');
      expect(persisted?.status, equals(BookingStatus.cancelled));
    });

    test('customer can cancel a booking with Confirmed status', () async {
      final result = await bookingService.cancelBooking(
        bookingId: 'bk-confirmed-03',
        customerId: customerId,
      );

      expect(result.status, equals(BookingStatus.cancelled));
      expect(result.cancelledBy, equals(customerId));

      final persisted = await bookingService.getBookingById('bk-confirmed-03');
      expect(persisted?.status, equals(BookingStatus.cancelled));
    });

    test('customer cannot cancel a booking that is In Progress', () async {
      expect(
        () => bookingService.cancelBooking(
          bookingId: 'bk-inprogress-04',
          customerId: customerId,
        ),
        throwsA(isA<CannotCancelBookingException>()),
      );

      final persisted = await bookingService.getBookingById('bk-inprogress-04');
      expect(persisted?.status, equals(BookingStatus.inProgress));
    });

    test('customer cannot cancel a booking that is Completed', () async {
      expect(
        () => bookingService.cancelBooking(
          bookingId: 'bk-completed-05',
          customerId: customerId,
        ),
        throwsA(isA<CannotCancelBookingException>()),
      );

      final persisted = await bookingService.getBookingById('bk-completed-05');
      expect(persisted?.status, equals(BookingStatus.completed));
    });

    test('customer cannot cancel a booking that is Declined', () async {
      expect(
        () => bookingService.cancelBooking(
          bookingId: 'bk-declined-06',
          customerId: customerId,
        ),
        throwsA(isA<CannotCancelBookingException>()),
      );

      final persisted = await bookingService.getBookingById('bk-declined-06');
      expect(persisted?.status, equals(BookingStatus.declined));
    });

    test('customer cannot cancel a booking that is already Cancelled', () async {
      await bookingService.cancelBooking(
        bookingId: 'bk-pending-01',
        customerId: customerId,
      );

      expect(
        () => bookingService.cancelBooking(
          bookingId: 'bk-pending-01',
          customerId: customerId,
        ),
        throwsA(isA<CannotCancelBookingException>()),
      );
    });

    test(
      'cancelled bookings cannot be accepted, assigned, or started afterward',
      () async {
        await bookingService.cancelBooking(
          bookingId: 'bk-pending-01',
          customerId: customerId,
        );

        // Cannot be accepted (Confirmed)
        expect(
          () => bookingService.acceptBooking(
            bookingId: 'bk-pending-01',
            providerId: 'prov-ac-01',
          ),
          throwsA(isA<InvalidBookingTransitionException>()),
        );

        // Cannot be assigned (Assigned)
        expect(
          () => bookingService.assignBooking(
            bookingId: 'bk-pending-01',
            technicianId: 'tech-01',
            technicianName: 'Sokha Vann',
          ),
          throwsA(isA<InvalidBookingTransitionException>()),
        );

        // Cannot be started (In Progress)
        expect(
          () => bookingService.startBooking(
            bookingId: 'bk-pending-01',
          ),
          throwsA(isA<InvalidBookingTransitionException>()),
        );
      },
    );

    test(
      'only the customer who created the booking can cancel it',
      () async {
        // Attempt by another user to cancel customer-1's booking
        expect(
          () => bookingService.cancelBooking(
            bookingId: 'bk-pending-01',
            customerId: 'unauthorized-user-777',
          ),
          throwsA(isA<UnauthorizedBookingCancellationException>()),
        );

        // Attempt by customer-1 to cancel another customer's booking
        expect(
          () => bookingService.cancelBooking(
            bookingId: 'bk-other-customer-99',
            customerId: customerId,
          ),
          throwsA(isA<UnauthorizedBookingCancellationException>()),
        );

        final untouched = await bookingService.getBookingById('bk-pending-01');
        expect(untouched?.status, equals(BookingStatus.pending));
      },
    );

    test('throws BookingNotFoundException for unknown bookingId', () async {
      expect(
        () => bookingService.cancelBooking(
          bookingId: 'bk-nonexistent',
          customerId: customerId,
        ),
        throwsA(isA<BookingNotFoundException>()),
      );
    });
  });
}
