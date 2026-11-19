import 'package:service_pilot/features/providers/models/provider_model.dart';

/// Contract for provider retrieval and query operations.
///
/// Corresponds to US-10 (SCRUM-55) & US-11 (SCRUM-54).
abstract class IProviderService {
  /// Fetches providers, optionally filtered by category and active status.
  Future<List<ProviderModel>> getProviders({
    String? categoryId,
    bool activeOnly = true,
  });

  /// Fetches a single provider by ID.
  Future<ProviderModel?> getProviderById(String id);

  /// Searches providers by query matching name, description, specialties, or coverage areas.
  Future<List<ProviderModel>> searchProviders(
    String query, {
    String? categoryId,
  });
}

/// Production-ready and mockable implementation of [IProviderService].
class ProviderService implements IProviderService {
  final List<ProviderModel> _providers;

  ProviderService({List<ProviderModel>? initialProviders})
      : _providers = initialProviders ?? defaultProviders;

  /// Default verified providers seeded for Phnom Penh districts.
  static final List<ProviderModel> defaultProviders = [
    const ProviderModel(
      id: 'prov-dara-ac',
      name: 'Dara Chhum',
      type: ProviderType.independent,
      description: 'Certified Inverter & Split AC Specialist',
      bio:
          'Certified HVAC technician with over 7 years of specialized experience in residential and boutique office cooling systems across Phnom Penh. Expert in eco-friendly R32 refrigerant recharging, precise coil wash, and PCB inverter diagnostics.',
      specialties: [
        'Inverter AC Diagnostics',
        'Chemical Coil Wash',
        'Refrigerant Leak Fix (R32/R410A)',
        'Compressor Replacement',
        'Wall-mount Installation',
      ],
      coverageAreas: ['Toul Kork', 'Sen Sok', 'Daun Penh'],
      categoryIds: ['cat-ac'],
      rating: 4.9,
      reviewCount: 38,
      completedJobsCount: 142,
      yearsExperience: 7,
      isAvailable: true,
      phoneNumber: '+855 12 345 678',
      email: 'dara.chhum@servicepilot.kh',
      startingPrice: 20.0,
      isVerified: true,
      status: 'active',
    ),
    const ProviderModel(
      id: 'prov-khmer-cool',
      name: 'Khmer Cool Aircon & Home Care Co., Ltd.',
      type: ProviderType.company,
      description: 'Premier Commercial & Residential HVAC Company',
      bio:
          'Licensed full-service cooling and appliance maintenance company based in Phnom Penh. Our uniformed, bonded technicians arrive equipped with heavy-duty diagnostic gear and factory-original replacement parts.',
      specialties: [
        'Central & Cassette AC Maintenance',
        'Duct Sanitization',
        'Multi-split VRV/VRF Systems',
        'Emergency 2-hour Response',
        'Annual Maintenance Contracts',
      ],
      coverageAreas: ['Chamkarmon', 'Toul Kork', 'Boeung Keng Kang', 'Sen Sok'],
      categoryIds: ['cat-ac', 'cat-appliance'],
      rating: 4.8,
      reviewCount: 64,
      completedJobsCount: 310,
      yearsExperience: 5,
      isAvailable: true,
      phoneNumber: '+855 23 888 999',
      email: 'support@khmercool.com.kh',
      startingPrice: 25.0,
      isVerified: true,
      status: 'active',
    ),
    const ProviderModel(
      id: 'prov-sopheap-plumbing',
      name: 'Sopheap Heng',
      type: ProviderType.independent,
      description: 'Master Plumber & Sanitary Engineer',
      bio:
          'Master plumber with 10 years of hands-on experience solving complex hydraulic issues in condominiums, shophouses, and boreys. Known for clean, non-invasive pipe repairs and rapid response.',
      specialties: [
        'Acoustic Pipe Leak Detection',
        'High-torque Drain Snaking',
        'Water Pump Installation & Servicing',
        'Hot Water Heater System Setup',
        'Bathroom Fixture Modernization',
      ],
      coverageAreas: ['Chamkarmon', 'Toul Kork', 'Chbar Ampov'],
      categoryIds: ['cat-plumbing'],
      rating: 4.95,
      reviewCount: 52,
      completedJobsCount: 215,
      yearsExperience: 10,
      // Unavailable provider for testing US-11 AC #5
      isAvailable: false,
      unavailableReason:
          'Fully booked for today. Next booking slots open tomorrow afternoon.',
      phoneNumber: '+855 17 654 321',
      email: 'sopheap.plumb@servicepilot.kh',
      startingPrice: 18.0,
      isVerified: true,
      status: 'active',
    ),
    const ProviderModel(
      id: 'prov-pp-plumbing-co',
      name: 'Phnom Penh Pro Plumbing',
      type: ProviderType.company,
      description: 'Commercial & Residential Plumbing Solutions',
      bio:
          'Trusted enterprise plumbing partner offering round-the-clock emergency dispatch across all core districts of Phnom Penh. Specializing in high-pressure water jetting and underground pipe mapping.',
      specialties: [
        'High-Pressure Hydro Jetting',
        'Underground Sewer Line Inspection',
        'Water Filtration Plant Setup',
        'Grease Trap De-clogging',
      ],
      coverageAreas: ['Sen Sok', 'Toul Kork', 'Daun Penh', 'Chamkarmon'],
      categoryIds: ['cat-plumbing'],
      rating: 4.7,
      reviewCount: 29,
      completedJobsCount: 180,
      yearsExperience: 4,
      isAvailable: true,
      phoneNumber: '+855 23 777 111',
      email: 'info@ppproplumbing.kh',
      startingPrice: 22.0,
      isVerified: true,
      status: 'active',
    ),
    const ProviderModel(
      id: 'prov-borith-electric',
      name: 'Borith Keo',
      type: ProviderType.independent,
      description: 'Certified Electrician & Smart Home Technician',
      bio:
          'Licensed electrician with deep expertise in residential electrical distribution boards, surge protection, and smart home automation integration in Phnom Penh apartments.',
      specialties: [
        'Circuit Breaker Box Replacement',
        'Short Circuit Fault Isolation',
        'Ceiling Fan & Chandelier Hanging',
        'Smart Relay & Switch Wiring',
      ],
      coverageAreas: ['Toul Kork', 'Sen Sok', 'Boeung Keng Kang'],
      categoryIds: ['cat-electrical'],
      rating: 4.85,
      reviewCount: 41,
      completedJobsCount: 165,
      yearsExperience: 6,
      isAvailable: true,
      phoneNumber: '+855 98 123 456',
      email: 'borith.keo@servicepilot.kh',
      startingPrice: 15.0,
      isVerified: true,
      status: 'active',
    ),
  ];

  @override
  Future<List<ProviderModel>> getProviders({
    String? categoryId,
    bool activeOnly = true,
  }) async {
    return _providers.where((p) {
      if (activeOnly && !p.isActive) return false;
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          !p.categoryIds.contains(categoryId)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<ProviderModel?> getProviderById(String id) async {
    try {
      return _providers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ProviderModel>> searchProviders(
    String query, {
    String? categoryId,
  }) async {
    final lower = query.trim().toLowerCase();
    final list = await getProviders(categoryId: categoryId);
    if (lower.isEmpty) return list;

    return list.where((p) {
      final nameMatches = p.name.toLowerCase().contains(lower);
      final descMatches = p.description.toLowerCase().contains(lower);
      final specialtyMatches =
          p.specialties.any((s) => s.toLowerCase().contains(lower));
      final areaMatches =
          p.coverageAreas.any((a) => a.toLowerCase().contains(lower));
      return nameMatches || descMatches || specialtyMatches || areaMatches;
    }).toList();
  }
}
