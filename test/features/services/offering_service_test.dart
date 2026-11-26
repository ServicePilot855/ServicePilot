import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';

void main() {
  group('SCRUM-77 / SCRUM-118: OfferingService Operations & Catalog Storage', () {
    late OfferingService service;

    setUp(() {
      service = OfferingService(
        initialOfferings: [
          const OfferingModel(
            id: 'item-1',
            providerId: 'prov-dara',
            providerName: 'Dara',
            categoryId: 'cat-ac',
            title: 'Split Wash',
            description: 'Routine AC coil wash',
            pricingMode: OfferingPricingMode.fixed,
            price: 20.0,
            isActive: true,
          ),
          const OfferingModel(
            id: 'item-2',
            providerId: 'prov-dara',
            providerName: 'Dara',
            categoryId: 'cat-ac',
            title: 'PCB Board Diagnostic',
            description: 'Inverter mainboard diagnostics requiring on-site price quote.',
            pricingMode: OfferingPricingMode.quoteRequired,
            price: null,
            isActive: true,
          ),
          const OfferingModel(
            id: 'item-3',
            providerId: 'prov-company',
            providerName: 'HVAC Co',
            categoryId: 'cat-ac',
            title: 'Chiller Inspection',
            description: 'Large commercial cooling plant diagnosis.',
            pricingMode: OfferingPricingMode.quoteRequired,
            price: null,
            isActive: false, // inactive
          ),
        ],
      );
    });

    test('getOfferings filters by category and active status', () async {
      final activeAcOfferings =
          await service.getOfferings(categoryId: 'cat-ac', activeOnly: true);

      expect(activeAcOfferings.length, 2);
      expect(activeAcOfferings.any((o) => o.id == 'item-1'), isTrue);
      expect(activeAcOfferings.any((o) => o.id == 'item-2'), isTrue);
      expect(activeAcOfferings.any((o) => o.id == 'item-3'), isFalse);
    });

    test('getOfferings filters by providerId', () async {
      final daraOfferings =
          await service.getOfferings(providerId: 'prov-dara');

      expect(daraOfferings.length, 2);
      expect(daraOfferings.every((o) => o.providerId == 'prov-dara'), isTrue);
    });

    test('createOffering sanitizes quote-required offerings by stripping fixed price',
        () async {
      const quoteOffering = OfferingModel(
        id: 'new-quote-offering',
        providerId: 'prov-dara',
        providerName: 'Dara',
        categoryId: 'cat-ac',
        title: 'Custom Ductwork',
        description: 'Custom ducting layout requiring quotation.',
        pricingMode: OfferingPricingMode.quoteRequired,
        price: 50.0, // Should be wiped out on store
      );

      final created = await service.createOffering(quoteOffering);
      expect(created.isQuoteRequired, isTrue);
      expect(created.price, isNull);
      expect(created.canAddToCart, isFalse);

      final fetched = await service.getOfferingById('new-quote-offering');
      expect(fetched, isNotNull);
      expect(fetched!.price, isNull);
    });

    test('updateOffering updates existing offering correctly', () async {
      final original = (await service.getOfferingById('item-1'))!;
      final updated = original.copyWith(
        title: 'Split Wash & Gas Top-up',
        price: 35.0,
      );

      final result = await service.updateOffering(updated);
      expect(result.title, 'Split Wash & Gas Top-up');
      expect(result.price, 35.0);

      final fetched = await service.getOfferingById('item-1');
      expect(fetched!.title, 'Split Wash & Gas Top-up');
    });

    test('deleteOffering removes offering from catalog', () async {
      await service.deleteOffering('item-2');
      final fetched = await service.getOfferingById('item-2');
      expect(fetched, isNull);
    });
  });
}
