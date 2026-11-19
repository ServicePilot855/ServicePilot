import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';

void main() {
  group('ProviderModel Unit Tests', () {
    final now = DateTime(2026, 1, 1);

    test('displayName returns businessName when provided, else name', () {
      final company = ProviderModel(
        id: '1',
        name: 'Sophea Lim',
        businessName: 'Phnom Penh Fix Co.',
        email: 'sophea@fixco.com',
        phone: '+855112233',
        type: ProviderType.company,
        serviceArea: 'Phnom Penh',
        categoryIds: const ['cat-plumbing'],
        createdAt: now,
      );

      expect(company.displayName, equals('Phnom Penh Fix Co.'));
      expect(company.isCompany, isTrue);
      expect(company.isIndependent, isFalse);
      expect(company.typeBadgeLabel, equals('Company'));

      final independent = ProviderModel(
        id: '2',
        name: 'Virak Chan',
        email: 'virak@test.com',
        phone: '+85587654321',
        type: ProviderType.independent,
        serviceArea: 'Toul Kork',
        categoryIds: const ['cat-ac'],
        createdAt: now,
      );

      expect(independent.displayName, equals('Virak Chan'));
      expect(independent.isCompany, isFalse);
      expect(independent.isIndependent, isTrue);
      expect(independent.typeBadgeLabel, equals('Independent'));
    });

    test('isApprovedAndActive and canAcceptBookings check status and availability', () {
      final activeAvailable = ProviderModel(
        id: '1',
        name: 'Active Tech',
        email: 'active@test.com',
        phone: '+855111111',
        type: ProviderType.independent,
        status: 'active',
        isAvailable: true,
        serviceArea: 'PP',
        categoryIds: const ['cat-ac'],
        createdAt: now,
      );

      expect(activeAvailable.isApprovedAndActive, isTrue);
      expect(activeAvailable.canAcceptBookings, isTrue);

      final activeBusy = activeAvailable.copyWith(isAvailable: false);
      expect(activeBusy.isApprovedAndActive, isTrue);
      expect(activeBusy.canAcceptBookings, isFalse);

      final pending = activeAvailable.copyWith(status: 'pending_verification');
      expect(pending.isApprovedAndActive, isFalse);
      expect(pending.canAcceptBookings, isFalse);
    });

    test('toMap and fromMap serialize and deserialize cleanly', () {
      final provider = ProviderModel(
        id: 'p123',
        name: 'Borey Nhem',
        businessName: 'Borey Electrical',
        email: 'borey@test.com',
        phone: '+855998877',
        type: ProviderType.independent,
        status: 'active',
        serviceArea: 'Daun Penh, Phnom Penh',
        categoryIds: const ['cat-electrical', 'cat-appliance'],
        rating: 4.8,
        reviewCount: 22,
        completedJobs: 65,
        hourlyRate: 16.0,
        bio: 'Residential electrical specialist.',
        isAvailable: true,
        avatarUrl: 'https://example.com/avatar.jpg',
        createdAt: now,
        updatedAt: DateTime(2026, 2, 1),
      );

      final map = provider.toMap();
      expect(map['name'], equals('Borey Nhem'));
      expect(map['businessName'], equals('Borey Electrical'));
      expect(map['type'], equals('independent'));
      expect(map['categoryIds'], equals(['cat-electrical', 'cat-appliance']));

      final deserialized = ProviderModel.fromMap(map, 'p123');
      expect(deserialized.id, equals('p123'));
      expect(deserialized.name, equals('Borey Nhem'));
      expect(deserialized.businessName, equals('Borey Electrical'));
      expect(deserialized.serviceArea, equals('Daun Penh, Phnom Penh'));
      expect(deserialized.categoryIds, equals(['cat-electrical', 'cat-appliance']));
      expect(deserialized.rating, equals(4.8));
      expect(deserialized.reviewCount, equals(22));
      expect(deserialized.completedJobs, equals(65));
      expect(deserialized.hourlyRate, equals(16.0));
    });
  });
}
