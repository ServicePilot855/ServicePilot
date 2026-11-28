import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';

void main() {
  const customerId = 'customer-1';
  const providerId = 'prov-virak-ac';
  const otherProviderId = 'prov-outsider-999';
  final now = DateTime(2026, 11, 28, 9, 0);

  BookingModel buildBooking({
    required String id,
    BookingStatus status = BookingStatus.confirmed,
    String provider = providerId,
    String? quoteId,
    String? technicianId,
    String? technicianName,
  }) {
    return BookingModel(
      id: id,
      customerId: customerId,
      providerId: provider,
      providerName: 'Virak Chan',
      serviceCategory: 'Air Conditioner Repair & Care',
      serviceTitle: 'Split AC Chemical Wash',
      description: 'AC unit dripping water indoors.',
      address: 'St. 310, BKK1, Phnom Penh',
      preferredDateTime: DateTime(2026, 11, 29, 14, 30),
      status: status,
      totalPrice: 25.0,
      createdAt: now,
      quoteId: quoteId,
      assignedTechnicianId: technicianId,
      assignedTechnicianName: technicianName,
      confirmedAppointmentAt:
          status == BookingStatus.confirmed || status == BookingStatus.assigned
              ? DateTime(2026, 11, 29, 14, 30)
              : null,
    );
  }

  QuoteRequestModel buildQuote({
    required String id,
    required QuoteStatus status,
    String? bookingId,
  }) {
    return QuoteRequestModel(
      id: id,
      customerId: customerId,
      providerId: providerId,
      providerName: 'Virak Chan',
      offeringId: 'offer-1',
      offeringTitle: 'AC deep clean',
      description: 'Please quote for a deep clean of two units.',
      status: status,
      quotedPrice: 45.0,
      approvedPrice: status == QuoteStatus.approved ? 45.0 : null,
      bookingId: bookingId,
      createdAt: now,
    );
  }

  group('SCRUM-91 / WORK-1: start an authorized provider job', () {
    test('independent provider starts their own confirmed job; customer sees In Progress',
        () async {
      final service = BookingService(
        initialBookings: [buildBooking(id: 'bk-start-1')],
        customerId: customerId,
      );

      final started = await service.startBooking(
        bookingId: 'bk-start-1',
        providerId: providerId,
      );

      expect(started.status, BookingStatus.inProgress);
      expect(started.updatedAt, isNotNull);

      final stored = await service.getBookingById('bk-start-1');
      expect(stored?.status, BookingStatus.inProgress);

      final customerView = await service.getCustomerBookings(customerId);
      expect(
        customerView.firstWhere((b) => b.id == 'bk-start-1').status,
        BookingStatus.inProgress,
      );
    });

    test('a company dispatcher can start an assigned job', () async {
      final service = BookingService(
        initialBookings: [
          buildBooking(
            id: 'bk-start-2',
            status: BookingStatus.assigned,
            technicianId: 'tech-1',
            technicianName: 'Sokha Vann',
          ),
        ],
        customerId: customerId,
      );

      final started = await service.startBooking(
        bookingId: 'bk-start-2',
        providerId: providerId,
      );

      expect(started.status, BookingStatus.inProgress);
    });

    test('another provider cannot start the job and the record is unchanged', () async {
      final service = BookingService(
        initialBookings: [buildBooking(id: 'bk-start-3')],
        customerId: customerId,
      );

      await expectLater(
        service.startBooking(
          bookingId: 'bk-start-3',
          providerId: otherProviderId,
        ),
        throwsA(isA<UnauthorizedBookingStartException>()),
      );

      expect(
        (await service.getBookingById('bk-start-3'))?.status,
        BookingStatus.confirmed,
      );
    });

    for (final status in [
      BookingStatus.pending,
      BookingStatus.cancelled,
      BookingStatus.completed,
      BookingStatus.declined,
      BookingStatus.inProgress,
    ]) {
      test('a ${status.value} job cannot start', () async {
        final service = BookingService(
          initialBookings: [buildBooking(id: 'bk-start-state', status: status)],
          customerId: customerId,
        );

        await expectLater(
          service.startBooking(
            bookingId: 'bk-start-state',
            providerId: providerId,
          ),
          throwsA(isA<InvalidBookingStartStateException>()),
        );

        expect(
          (await service.getBookingById('bk-start-state'))?.status,
          status,
        );
      });
    }

    test('quote work cannot start until the homeowner approves the quote', () async {
      final quote = buildQuote(id: 'q-1', status: QuoteStatus.quoted);
      final service = BookingService(
        initialBookings: [buildBooking(id: 'bk-start-quote', quoteId: 'q-1')],
        customerId: customerId,
        findQuote: (id) async => id == 'q-1' ? quote : null,
      );

      await expectLater(
        service.startBooking(
          bookingId: 'bk-start-quote',
          providerId: providerId,
        ),
        throwsA(isA<QuoteNotApprovedForStartException>()),
      );

      expect(
        (await service.getBookingById('bk-start-quote'))?.status,
        BookingStatus.confirmed,
      );
    });

    test('quote work cannot start when the quote is missing', () async {
      final service = BookingService(
        initialBookings: [buildBooking(id: 'bk-start-missing', quoteId: 'q-gone')],
        customerId: customerId,
        findQuote: (_) async => null,
      );

      await expectLater(
        service.startBooking(
          bookingId: 'bk-start-missing',
          providerId: providerId,
        ),
        throwsA(isA<QuoteNotApprovedForStartException>()),
      );
    });

    test('approved quote work starts and the record stays In Progress', () async {
      final quote = buildQuote(
        id: 'q-2',
        status: QuoteStatus.approved,
        bookingId: 'bk-start-approved',
      );
      final service = BookingService(
        initialBookings: [
          buildBooking(id: 'bk-start-approved', quoteId: 'q-2'),
        ],
        customerId: customerId,
        findQuote: (id) async => id == 'q-2' ? quote : null,
      );

      final started = await service.startBooking(
        bookingId: 'bk-start-approved',
        providerId: providerId,
      );

      expect(started.status, BookingStatus.inProgress);
    });

    test('throws BookingNotFoundException for an unknown booking', () async {
      final service = BookingService(
        initialBookings: const [],
        customerId: customerId,
      );

      await expectLater(
        service.startBooking(
          bookingId: 'bk-missing',
          providerId: providerId,
        ),
        throwsA(isA<BookingNotFoundException>()),
      );
    });
  });

  group('SCRUM-91 / WORK-1: BookingModel start eligibility', () {
    test('only confirmed and assigned jobs can start', () {
      expect(buildBooking(id: 'm1', status: BookingStatus.confirmed).canBeStarted, isTrue);
      expect(buildBooking(id: 'm2', status: BookingStatus.assigned).canBeStarted, isTrue);
      expect(buildBooking(id: 'm3', status: BookingStatus.pending).canBeStarted, isFalse);
      expect(buildBooking(id: 'm4', status: BookingStatus.inProgress).canBeStarted, isFalse);
      expect(buildBooking(id: 'm5', status: BookingStatus.cancelled).canBeStarted, isFalse);
    });

    test('only the owning provider can start', () {
      final booking = buildBooking(id: 'm6');
      expect(booking.canBeStartedBy(providerId), isTrue);
      expect(booking.canBeStartedBy(otherProviderId), isFalse);
    });
  });
}
