import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';

void main() {
  group('ProviderModel Unit Tests', () {
    const testProvider = ProviderModel(
      id: 'prov-test-01',
      name: 'Dara Technician',
      type: ProviderType.independent,
      description: 'Expert AC technician in Phnom Penh',
      bio: 'Over 8 years repairing all major brands.',
      specialties: ['Inverter Repair', 'Coil Wash'],
      coverageAreas: ['Toul Kork', 'Sen Sok'],
      categoryIds: ['cat-ac'],
      rating: 4.9,
      reviewCount: 30,
      completedJobsCount: 120,
      yearsExperience: 8,
      isAvailable: true,
      phoneNumber: '+855 12 345 678',
      email: 'dara@test.com',
      startingPrice: 20.0,
      isVerified: true,
      status: 'active',
    );

    test('serializes to and from JSON correctly', () {
      final json = testProvider.toJson();
      expect(json['id'], 'prov-test-01');
      expect(json['name'], 'Dara Technician');
      expect(json['type'], 'independent');
      expect(json['rating'], 4.9);
      expect(json['isAvailable'], true);
      expect(json['specialties'], ['Inverter Repair', 'Coil Wash']);
      expect(json['coverageAreas'], ['Toul Kork', 'Sen Sok']);

      final restored = ProviderModel.fromJson(json);
      expect(restored.id, testProvider.id);
      expect(restored.name, testProvider.name);
      expect(restored.type, ProviderType.independent);
      expect(restored.isIndependent, true);
      expect(restored.isCompany, false);
      expect(restored.canAcceptBookings, true);
      expect(restored.specialties, contains('Inverter Repair'));
      expect(restored.coverageAreas, contains('Toul Kork'));
    });

    test('canAcceptBookings respects availability and active status', () {
      expect(testProvider.canAcceptBookings, true);

      final unavailableProvider = testProvider.copyWith(
        isAvailable: false,
        unavailableReason: 'Fully booked',
      );
      expect(unavailableProvider.canAcceptBookings, false);
      expect(unavailableProvider.unavailableReason, 'Fully booked');

      final inactiveProvider = testProvider.copyWith(
        status: 'suspended',
      );
      expect(inactiveProvider.canAcceptBookings, false);
    });

    test('company provider flags and badges work as expected', () {
      const company = ProviderModel(
        id: 'prov-comp-01',
        name: 'Cool Aircon Co.',
        type: ProviderType.company,
        description: 'AC Company',
        bio: 'HVAC repair enterprise',
        coverageAreas: ['Chamkarmon'],
      );

      expect(company.isCompany, true);
      expect(company.isIndependent, false);
      expect(company.typeDisplayName, 'Repair Company');
      expect(company.formattedCoverageAreas, 'Chamkarmon');
      expect(company.formattedRating, '5.0');
    });

    test('copyWith updates specified fields only', () {
      final updated = testProvider.copyWith(
        name: 'Dara Chhum (Senior)',
        rating: 5.0,
        isAvailable: false,
      );

      expect(updated.id, testProvider.id);
      expect(updated.name, 'Dara Chhum (Senior)');
      expect(updated.rating, 5.0);
      expect(updated.isAvailable, false);
      expect(updated.bio, testProvider.bio);
    });
  });
}
