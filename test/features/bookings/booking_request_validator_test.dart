import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';

void main() {
  group('SCRUM-43 / US-12: BookingRequestValidator', () {
    final now = DateTime(2026, 11, 20, 10, 0);

    BookingRequest request({
      String service = 'Chemical Coil Wash',
      String description = 'Bedroom AC blows warm air and drips water.',
      String address = 'St. 310, BKK1, Chamkarmon',
      DateTime? when,
    }) {
      return BookingRequest(
        customerId: 'customer-1',
        providerId: 'prov-1',
        providerName: 'Dara Chhum',
        serviceCategory: 'Air Conditioner Repair',
        serviceTitle: service,
        description: description,
        address: address,
        preferredDateTime: when ?? now.add(const Duration(days: 1)),
      );
    }

    test('a complete request has no errors', () {
      expect(BookingRequestValidator.validate(request(), now: now), isEmpty);
    });

    test('service is required', () {
      expect(BookingRequestValidator.service(null),
          BookingFieldError.serviceRequired);
      expect(BookingRequestValidator.service('  '),
          BookingFieldError.serviceRequired);
    });

    test('description must be present, detailed enough and not too long', () {
      expect(BookingRequestValidator.description(''),
          BookingFieldError.descriptionRequired);
      expect(BookingRequestValidator.description('AC broken'),
          BookingFieldError.descriptionTooShort);
      expect(
        BookingRequestValidator.description('x' * 1001),
        BookingFieldError.descriptionTooLong,
      );
      expect(
        BookingRequestValidator.description('   Leaking pipe under sink   '),
        isNull,
      );
    });

    test('address must be present and a usable length', () {
      expect(BookingRequestValidator.address(null),
          BookingFieldError.addressRequired);
      expect(BookingRequestValidator.address('BKK1'),
          BookingFieldError.addressTooShort);
      expect(BookingRequestValidator.address('x' * 301),
          BookingFieldError.addressTooLong);
    });

    test('date and time must be chosen and in the future', () {
      expect(BookingRequestValidator.preferredDateTime(null, now: now),
          BookingFieldError.dateTimeRequired);
      expect(
        BookingRequestValidator.preferredDateTime(
          now.subtract(const Duration(hours: 2)),
          now: now,
        ),
        BookingFieldError.dateTimeTooSoon,
      );
      expect(
        BookingRequestValidator.preferredDateTime(
          now.add(const Duration(minutes: 30)),
          now: now,
        ),
        BookingFieldError.dateTimeTooSoon,
      );
      expect(
        BookingRequestValidator.preferredDateTime(
          now.add(const Duration(days: 61)),
          now: now,
        ),
        BookingFieldError.dateTimeTooFar,
      );
      expect(
        BookingRequestValidator.preferredDateTime(
          now.add(const Duration(hours: 2)),
          now: now,
        ),
        isNull,
      );
    });

    test('photos are optional, at most 5, each at most 5 MB', () {
      BookingPhoto photo(int bytes) =>
          BookingPhoto(bytes: Uint8List(bytes), name: 'leak.jpg');

      expect(BookingRequestValidator.photos(const []), isNull);
      expect(BookingRequestValidator.photos(List.filled(5, photo(10))), isNull);
      expect(BookingRequestValidator.photos(List.filled(6, photo(10))),
          BookingFieldError.tooManyPhotos);
      expect(
        BookingRequestValidator.photos([photo(5 * 1024 * 1024 + 1)]),
        BookingFieldError.photoTooLarge,
      );
    });

    test('validate lists every problem in form order', () {
      final errors = BookingRequestValidator.validate(
        request(service: '', description: '', address: '', when: now),
        now: now,
      );
      expect(errors, [
        BookingFieldError.serviceRequired,
        BookingFieldError.descriptionRequired,
        BookingFieldError.addressRequired,
        BookingFieldError.dateTimeTooSoon,
      ]);
    });
  });
}
