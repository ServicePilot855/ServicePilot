import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/providers/services/firestore_provider_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirestoreProviderService Unit & Fallback Tests', () {
    late FirestoreProviderService service;

    setUp(() {
      service = FirestoreProviderService();
    });

    test('getProvidersByCategory returns only active approved providers for given category', () async {
      // cat-ac has active providers (Virak Chan, Fix Co, CleanPro)
      final acProviders = await service.getProvidersByCategory('cat-ac');

      expect(acProviders, isNotEmpty);
      expect(acProviders.every((p) => p.status == 'active'), isTrue);
      expect(acProviders.every((p) => p.categoryIds.contains('cat-ac')), isTrue);

      // Verify that unapproved/pending provider (Sokha Pich) is NOT included (US-10 AC)
      final hasPending = acProviders.any((p) => p.status == 'pending_verification');
      expect(hasPending, isFalse);
    });

    test('getProvidersByCategory returns both independent and company providers', () async {
      final acProviders = await service.getProvidersByCategory('cat-ac');

      final hasIndependent = acProviders.any((p) => p.isIndependent);
      final hasCompany = acProviders.any((p) => p.isCompany);

      expect(hasIndependent, isTrue);
      expect(hasCompany, isTrue);
    });

    test('getProvidersByCategory returns empty list for category with no providers', () async {
      final locksmithProviders = await service.getProvidersByCategory('cat-locksmith');
      expect(locksmithProviders, isEmpty);
    });

    test('getProviderById returns correct provider model when found', () async {
      final provider = await service.getProviderById('prov-virak-ac');

      expect(provider, isNotNull);
      expect(provider?.name, equals('Virak Chan'));
      expect(provider?.serviceArea, contains('Toul Kork'));
      expect(provider?.isAvailable, isTrue);
    });

    test('getProviderById returns null when provider does not exist', () async {
      final provider = await service.getProviderById('non-existent-id');
      expect(provider, isNull);
    });
  });
}
