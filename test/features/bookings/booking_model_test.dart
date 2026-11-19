import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';

void main() {
  group('SCRUM-45 / US-14: BookingStatus & BookingModel Unit Tests', () {
    final baseBooking = BookingModel(
      id: 'bk-test-01',
      customerId: 'customer-1',
      providerId: 'provider-1',
      providerName: 'Phnom Penh CoolAir Engineering',
      serviceCategory: 'Air Conditioner Repair & Care',
      serviceTitle: 'AC Deep Chemical Wash',
      description: 'AC leaking water',
      address: 'BKK1, Chamkarmon, Phnom Penh',
      preferredDateTime: DateTime(2026, 11, 25, 14, 0),
      status: BookingStatus.pending,
      totalPrice: 25.0,
      createdAt: DateTime(2026, 11, 20, 9, 0),
    );

    test(
      'canBeCancelled is true ONLY for Pending, Assigned, and Confirmed',
      () {
        expect(BookingStatus.pending.canBeCancelled, isTrue);
        expect(BookingStatus.assigned.canBeCancelled, isTrue);
        expect(BookingStatus.confirmed.canBeCancelled, isTrue);

        expect(BookingStatus.inProgress.canBeCancelled, isFalse);
        expect(BookingStatus.completed.canBeCancelled, isFalse);
        expect(BookingStatus.cancelled.canBeCancelled, isFalse);
        expect(BookingStatus.declined.canBeCancelled, isFalse);
      },
    );

    test(
      'cancelled bookings cannot transition to confirmed (accepted), assigned, or inProgress (started)',
      () {
        expect(
          BookingStatus.cancelled.canTransitionTo(BookingStatus.confirmed),
          isFalse,
        );
        expect(
          BookingStatus.cancelled.canTransitionTo(BookingStatus.assigned),
          isFalse,
        );
        expect(
          BookingStatus.cancelled.canTransitionTo(BookingStatus.inProgress),
          isFalse,
        );
        expect(
          BookingStatus.cancelled.canTransitionTo(BookingStatus.completed),
          isFalse,
        );
      },
    );

    test(
      'canBeCancelledBy checks both customer ownership and cancellable status',
      () {
        expect(baseBooking.canBeCancelledBy('customer-1'), isTrue);
        expect(baseBooking.canBeCancelledBy('other-customer'), isFalse);

        final inProgressBooking = baseBooking.copyWith(
          status: BookingStatus.inProgress,
        );
        expect(inProgressBooking.canBeCancelledBy('customer-1'), isFalse);
      },
    );

    test('JSON serialization and deserialization round-trips accurately', () {
      final cancelledBooking = baseBooking.copyWith(
        status: BookingStatus.cancelled,
        cancelledAt: DateTime(2026, 11, 20, 11, 30),
        cancelledBy: 'customer-1',
        cancellationReason: 'Problem resolved',
      );

      final json = cancelledBooking.toJson();
      final restored = BookingModel.fromJson(json);

      expect(restored.id, equals(cancelledBooking.id));
      expect(restored.customerId, equals('customer-1'));
      expect(restored.status, equals(BookingStatus.cancelled));
      expect(restored.cancelledBy, equals('customer-1'));
      expect(restored.cancellationReason, equals('Problem resolved'));
      expect(restored.cancelledAt, equals(DateTime(2026, 11, 20, 11, 30)));
    });
  });
}
