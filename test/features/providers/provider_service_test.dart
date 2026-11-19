import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';

void main() {
  group('ProviderService Unit Tests', () {
    late ProviderService service;

    setUp(() {
      service = ProviderService();
    });

    test('getProviders returns active verified providers', () async {
      final providers = await service.getProviders();
      expect(providers, isNotEmpty);
      expect(providers.every((p) => p.isActive), isTrue);
    });

    test('getProviders filters by categoryId correctly', () async {
      final acProviders = await service.getProviders(categoryId: 'cat-ac');
      expect(acProviders, isNotEmpty);
      expect(acProviders.every((p) => p.categoryIds.contains('cat-ac')), isTrue);

      final plumbingProviders =
          await service.getProviders(categoryId: 'cat-plumbing');
      expect(plumbingProviders, isNotEmpty);
      expect(
          plumbingProviders.every((p) => p.categoryIds.contains('cat-plumbing')),
          isTrue);
    });

    test('getProviderById retrieves expected provider or null for invalid ID',
        () async {
      final provider = await service.getProviderById('prov-dara-ac');
      expect(provider, isNotNull);
      expect(provider!.name, 'Dara Chhum');
      expect(provider.isIndependent, isTrue);

      final nonExistent = await service.getProviderById('invalid-id-999');
      expect(nonExistent, isNull);
    });

    test('searchProviders matches by name, specialties, and coverage areas',
        () async {
      final byName = await service.searchProviders('Dara');
      expect(byName.any((p) => p.name.contains('Dara')), isTrue);

      final bySpecialty = await service.searchProviders('Inverter');
      expect(
        bySpecialty.any((p) =>
            p.specialties.any((s) => s.toLowerCase().contains('inverter'))),
        isTrue,
      );

      final byArea = await service.searchProviders('Toul Kork');
      expect(
        byArea.any((p) => p.coverageAreas.contains('Toul Kork')),
        isTrue,
      );
    });

    test('default dataset includes both independent and company providers',
        () async {
      final providers = await service.getProviders();
      final hasIndependent =
          providers.any((p) => p.type == ProviderType.independent);
      final hasCompany = providers.any((p) => p.type == ProviderType.company);

      expect(hasIndependent, isTrue);
      expect(hasCompany, isTrue);
    });

    test('default dataset includes unavailable provider for AC #5 validation',
        () async {
      final provider = await service.getProviderById('prov-sopheap-plumbing');
      expect(provider, isNotNull);
      expect(provider!.isAvailable, isFalse);
      expect(provider.canAcceptBookings, isFalse);
      expect(provider.unavailableReason, isNotNull);
    });
  });
}
