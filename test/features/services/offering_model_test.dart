import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';

void main() {
  group('SCRUM-77 / SCRUM-118: OfferingModel Unit Tests (OFFER-2)', () {
    test('OfferingPricingMode parses and serializes correctly', () {
      expect(OfferingPricingMode.fromValue('quote_required'),
          OfferingPricingMode.quoteRequired);
      expect(OfferingPricingMode.fromValue('quoteRequired'),
          OfferingPricingMode.quoteRequired);
      expect(OfferingPricingMode.fromValue('quote'),
          OfferingPricingMode.quoteRequired);
      expect(
          OfferingPricingMode.fromValue('fixed'), OfferingPricingMode.fixed);
      expect(OfferingPricingMode.fromValue('unknown'), OfferingPricingMode.fixed);

      expect(OfferingPricingMode.quoteRequired.value, 'quote_required');
      expect(OfferingPricingMode.fixed.value, 'fixed');
    });

    test('Quote-required mode enforces cart isolation (canAddToCart is false)',
        () {
      const quoteOffering = OfferingModel(
        id: 'off-1',
        providerId: 'prov-1',
        providerName: 'Test Tech',
        categoryId: 'cat-ac',
        title: 'Central AC Overhaul',
        description: 'Comprehensive commercial HVAC inspection and diagnostics.',
        pricingMode: OfferingPricingMode.quoteRequired,
      );

      expect(quoteOffering.isQuoteRequired, isTrue);
      expect(quoteOffering.isFixedPrice, isFalse);
      expect(quoteOffering.canAddToCart, isFalse);
      expect(quoteOffering.requiresQuoteIntake, isTrue);
      expect(quoteOffering.priceDisplay, 'Quote Required');
    });

    test('Fixed-price mode allows cart checkout (canAddToCart is true)', () {
      const fixedOffering = OfferingModel(
        id: 'off-2',
        providerId: 'prov-1',
        providerName: 'Test Tech',
        categoryId: 'cat-ac',
        title: 'Filter Wash',
        description: 'Standard filter cleaning and wash.',
        pricingMode: OfferingPricingMode.fixed,
        price: 15.0,
        unit: 'unit',
      );

      expect(fixedOffering.isQuoteRequired, isFalse);
      expect(fixedOffering.isFixedPrice, isTrue);
      expect(fixedOffering.canAddToCart, isTrue);
      expect(fixedOffering.requiresQuoteIntake, isFalse);
      expect(fixedOffering.priceDisplay, '\$15.00 / unit');
    });

    test('Serialization toMap strips price when mode is quoteRequired', () {
      const quoteOfferingWithPrice = OfferingModel(
        id: 'off-3',
        providerId: 'prov-2',
        providerName: 'Company HVAC',
        providerType: ProviderType.company,
        categoryId: 'cat-ac',
        categoryName: 'Air Conditioner',
        title: 'Duct Overhaul',
        description: 'Deep duct cleaning requiring on-site quote.',
        pricingMode: OfferingPricingMode.quoteRequired,
        price: 99.0, // should be stripped in toMap
        unit: 'job',
        isActive: true,
      );

      final map = quoteOfferingWithPrice.toMap();
      expect(map['pricingMode'], 'quote_required');
      expect(map['price'], isNull); // Enforces checkout exclusion
      expect(map['providerType'], 'company');
      expect(map['title'], 'Duct Overhaul');
    });

    test('Deserialization fromMap correctly parses quote offering', () {
      final data = {
        'id': 'off-4',
        'providerId': 'prov-3',
        'providerName': 'Sopheap Plumber',
        'providerType': 'independent',
        'categoryId': 'cat-plumbing',
        'categoryName': 'Plumbing & Drainage',
        'title': 'Underground Sonar Leak Check',
        'description': 'Advanced ultrasonic acoustic leak detection.',
        'pricingMode': 'quote_required',
        'price': null,
        'isActive': true,
        'createdAt': '2026-11-21T10:00:00.000Z',
      };

      final offering = OfferingModel.fromMap(data, 'off-4');
      expect(offering.id, 'off-4');
      expect(offering.isQuoteRequired, isTrue);
      expect(offering.price, isNull);
      expect(offering.canAddToCart, isFalse);
      expect(offering.providerType, ProviderType.independent);
      expect(offering.createdAt, isNotNull);
    });

    test('copyWith updates properties properly while maintaining immutability',
        () {
      const original = OfferingModel(
        id: 'off-5',
        providerId: 'prov-1',
        providerName: 'Test Tech',
        categoryId: 'cat-ac',
        title: 'AC Fix',
        description: 'AC fix description.',
        pricingMode: OfferingPricingMode.fixed,
        price: 25.0,
      );

      final updated = original.copyWith(
        title: 'Updated AC Fix',
        pricingMode: OfferingPricingMode.quoteRequired,
        price: null,
      );

      expect(updated.title, 'Updated AC Fix');
      expect(updated.isQuoteRequired, isTrue);
      expect(updated.canAddToCart, isFalse);
      expect(original.isQuoteRequired, isFalse);
    });
  });
}
