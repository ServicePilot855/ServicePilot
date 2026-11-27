import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/quotes/models/quote_request_input.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';

OfferingModel _quoteOffering({
  String id = 'offering-dara-pcb-quote',
  String providerId = 'prov-dara-ac',
  OfferingPricingMode pricingMode = OfferingPricingMode.quoteRequired,
  double? price,
  bool isActive = true,
}) {
  return OfferingModel(
    id: id,
    providerId: providerId,
    providerName: 'Dara Chhum',
    categoryId: 'cat-ac',
    categoryName: 'Air Conditioner Repair & Care',
    title: 'Inverter Mainboard & PCB Replacement',
    description: 'Requires on-site diagnostics and custom quote.',
    pricingMode: pricingMode,
    price: price,
    isActive: isActive,
  );
}

BookingPhoto _photo(String name, {int size = 4}) => BookingPhoto(
      bytes: Uint8List(size),
      name: name,
    );

void main() {
  group('SCRUM-83 / QUOTE-1: QuoteRequestValidator', () {
    test('accepts a valid quote-required offering, description, and photos',
        () {
      final input = QuoteRequestInput(
        customerId: 'customer-1',
        providerId: 'prov-dara-ac',
        providerName: 'Dara Chhum',
        offering: _quoteOffering(),
        description: 'Indoor unit shows E5 fault code after power surge.',
        photos: [_photo('pcb.jpg')],
      );

      expect(QuoteRequestValidator.validate(input), isEmpty);
    });

    test('rejects fixed-price offerings from quote requests', () {
      final input = QuoteRequestInput(
        customerId: 'customer-1',
        providerId: 'prov-dara-ac',
        providerName: 'Dara Chhum',
        offering: _quoteOffering(
          pricingMode: OfferingPricingMode.fixed,
          price: 25.0,
        ),
        description: 'Indoor unit shows E5 fault code after power surge.',
      );

      expect(
        QuoteRequestValidator.validate(input),
        contains(QuoteFieldError.offeringNotQuoteRequired),
      );
    });

    test('rejects inactive offerings and mismatched provider offerings', () {
      final inactive = QuoteRequestInput(
        customerId: 'customer-1',
        providerId: 'prov-dara-ac',
        providerName: 'Dara Chhum',
        offering: _quoteOffering(isActive: false),
        description: 'Indoor unit shows E5 fault code after power surge.',
      );
      expect(
        QuoteRequestValidator.validate(inactive),
        contains(QuoteFieldError.offeringInactive),
      );

      final mismatched = QuoteRequestInput(
        customerId: 'customer-1',
        providerId: 'prov-other',
        providerName: 'Other Provider',
        offering: _quoteOffering(providerId: 'prov-dara-ac'),
        description: 'Indoor unit shows E5 fault code after power surge.',
      );
      expect(
        QuoteRequestValidator.validate(mismatched),
        contains(QuoteFieldError.offeringProviderMismatch),
      );
    });

    test('enforces description presence and length bounds', () {
      expect(
        QuoteRequestValidator.description(''),
        QuoteFieldError.descriptionRequired,
      );
      expect(
        QuoteRequestValidator.description('   too short '),
        QuoteFieldError.descriptionTooShort,
      );
      expect(
        QuoteRequestValidator.description(
          'a' * (BookingRequestValidator.descriptionMaxLength + 1),
        ),
        QuoteFieldError.descriptionTooLong,
      );
      expect(
        QuoteRequestValidator.description('Bedroom AC unit refuses to power on.'),
        isNull,
      );
    });

    test('enforces photo count and size limits', () {
      final sixPhotos = [
        for (var i = 0; i < BookingRequestValidator.maxPhotos + 1; i++)
          _photo('p$i.jpg'),
      ];
      expect(
        QuoteRequestValidator.photos(sixPhotos),
        QuoteFieldError.tooManyPhotos,
      );

      final oversized = [
        _photo('huge.jpg', size: BookingRequestValidator.maxPhotoBytes + 1),
      ];
      expect(
        QuoteRequestValidator.photos(oversized),
        QuoteFieldError.photoTooLarge,
      );
    });
  });
}
