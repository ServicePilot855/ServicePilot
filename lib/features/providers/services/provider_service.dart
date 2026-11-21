import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';

/// Thrown when a requested provider ID does not exist.
class ProviderNotFoundException implements Exception {
  final String providerId;
  final String message;

  const ProviderNotFoundException(
    this.providerId, [
    this.message = 'The requested service provider could not be found.',
  ]);

  @override
  String toString() => 'ProviderNotFoundException($providerId): $message';
}

/// Thrown when a non-admin or unauthenticated account attempts to review or approve a provider.
///
/// Enforces ADM-2 (SCRUM-94 / SCRUM-162) AC:
/// "A non-admin account cannot approve a provider."
class UnauthorizedProviderApprovalException implements Exception {
  final String? providerId;
  final String? userId;
  final String? role;
  final String message;

  const UnauthorizedProviderApprovalException({
    this.providerId,
    this.userId,
    this.role,
    this.message =
        'Only an authorized Platform Admin can approve a provider application.',
  });

  @override
  String toString() =>
      'UnauthorizedProviderApprovalException(providerId: $providerId, userId: $userId, role: $role): $message';
}

/// Thrown when an approval is attempted on a provider record that is not in
/// `pending_verification` status.
///
/// Enforces ADM-2 (SCRUM-94 / SCRUM-162) AC:
/// "An authorized admin can approve a Pending Verification provider."
class InvalidProviderApprovalStateException implements Exception {
  final String providerId;
  final String currentStatus;
  final String message;

  InvalidProviderApprovalStateException({
    required this.providerId,
    required this.currentStatus,
    String? message,
  }) : message =
           message ??
           'Cannot approve provider "$providerId" with status "$currentStatus". '
               'Only Pending Verification providers can be approved.';

  @override
  String toString() =>
      'InvalidProviderApprovalStateException(providerId: $providerId, status: $currentStatus): $message';
}

/// Contract for provider retrieval, query, and admin approval operations.
///
/// Corresponds to US-10 (SCRUM-55), US-11 (SCRUM-54), and ADM-2 (SCRUM-94).
abstract class IProviderService {
  /// Fetches providers, optionally filtered by category and active status.
  Future<List<ProviderModel>> getProviders({
    String? categoryId,
    bool activeOnly = true,
  });

  /// Fetches approved and active service providers offering services in [categoryId].
  Future<List<ProviderModel>> getProvidersByCategory(String categoryId);

  /// Fetches a single provider by ID.
  Future<ProviderModel?> getProviderById(String id);

  /// Searches providers by query matching name, description, specialties, or coverage areas.
  Future<List<ProviderModel>> searchProviders(
    String query, {
    String? categoryId,
  });

  /// Fetches providers currently in `pending_verification` status for admin review.
  ///
  /// Throws [UnauthorizedProviderApprovalException] if [actor] is not a Platform Admin.
  Future<List<ProviderModel>> getPendingProviders({
    required UserModel? actor,
  });

  /// Approves a `pending_verification` provider so it becomes `active`, verified,
  /// and eligible for customer discovery and bookings (ADM-2 / SCRUM-94).
  ///
  /// Throws:
  /// - [UnauthorizedProviderApprovalException] if [actor] is null or not [AppRole.admin].
  /// - [ProviderNotFoundException] if [providerId] does not exist.
  /// - [InvalidProviderApprovalStateException] if the provider is not in `pending_verification` status.
  Future<ProviderModel> approveProvider({
    required String providerId,
    required UserModel? actor,
  });

  /// Seeds initial demo providers into the database for rapid testing and bootstrapping.
  Future<void> seedInitialProviders();
}

/// Production-ready and mockable implementation of [IProviderService].
class ProviderService implements IProviderService {
  final List<ProviderModel> _providers;

  ProviderService({List<ProviderModel>? initialProviders})
      : _providers = List<ProviderModel>.from(
          initialProviders ?? defaultProviders,
        );

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
      serviceArea: 'Toul Kork, Sen Sok, Daun Penh',
      categoryIds: ['cat-ac'],
      rating: 4.9,
      reviewCount: 38,
      completedJobs: 142,
      yearsExperience: 7,
      hourlyRate: 20.0,
      isAvailable: true,
      phone: '+855 12 345 678',
      email: 'dara.chhum@servicepilot.kh',
      isVerified: true,
      status: 'active',
    ),
    const ProviderModel(
      id: 'prov-khmer-cool',
      name: 'Khmer Cool Aircon & Home Care Co., Ltd.',
      businessName: 'Khmer Cool Aircon & Home Care Co., Ltd.',
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
      serviceArea: 'Chamkarmon, Toul Kork, Boeung Keng Kang, Sen Sok',
      categoryIds: ['cat-ac', 'cat-appliance'],
      rating: 4.8,
      reviewCount: 64,
      completedJobs: 310,
      yearsExperience: 5,
      hourlyRate: 25.0,
      isAvailable: true,
      phone: '+855 23 888 999',
      email: 'support@khmercool.com.kh',
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
      serviceArea: 'Chamkarmon, Toul Kork, Chbar Ampov',
      categoryIds: ['cat-plumbing'],
      rating: 4.95,
      reviewCount: 52,
      completedJobs: 215,
      yearsExperience: 10,
      isAvailable: false,
      unavailableReason:
          'Fully booked for today. Next booking slots open tomorrow afternoon.',
      phone: '+855 17 654 321',
      email: 'sopheap.plumb@servicepilot.kh',
      hourlyRate: 18.0,
      isVerified: true,
      status: 'active',
    ),
    const ProviderModel(
      id: 'prov-pp-plumbing-co',
      name: 'Phnom Penh Pro Plumbing',
      businessName: 'Phnom Penh Pro Plumbing',
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
      serviceArea: 'Sen Sok, Toul Kork, Daun Penh, Chamkarmon',
      categoryIds: ['cat-plumbing'],
      rating: 4.7,
      reviewCount: 29,
      completedJobs: 180,
      yearsExperience: 4,
      hourlyRate: 22.0,
      isAvailable: true,
      phone: '+855 23 777 111',
      email: 'info@ppproplumbing.kh',
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
      serviceArea: 'Toul Kork, Sen Sok, Boeung Keng Kang',
      categoryIds: ['cat-electrical'],
      rating: 4.85,
      reviewCount: 41,
      completedJobs: 165,
      yearsExperience: 6,
      hourlyRate: 15.0,
      isAvailable: true,
      phone: '+855 98 123 456',
      email: 'borith.keo@servicepilot.kh',
      isVerified: true,
      status: 'active',
    ),
    const ProviderModel(
      id: 'prov-virak-ac',
      name: 'Virak Chan',
      type: ProviderType.independent,
      description: 'Certified Inverter & Split AC Specialist',
      bio:
          'Certified HVAC technician with 7+ years of experience in Daikin, Panasonic, and LG inverter systems. Expert in chemical cleaning and leak diagnosis.',
      specialties: ['Inverter Repair', 'Chemical Cleaning', 'Leak Diagnosis'],
      coverageAreas: ['Toul Kork'],
      serviceArea: 'Toul Kork, Phnom Penh',
      categoryIds: ['cat-ac', 'cat-electrical'],
      rating: 4.9,
      reviewCount: 42,
      completedJobs: 118,
      hourlyRate: 15.0,
      isAvailable: true,
      phone: '+85587654321',
      email: 'technician@test.com',
      status: 'active',
    ),
    const ProviderModel(
      id: 'prov-fixco-company',
      name: 'Sophea Lim',
      businessName: 'Phnom Penh Fix Co.',
      type: ProviderType.company,
      description: 'Licensed maintenance company with 12 dispatched technicians',
      bio:
          'Licensed maintenance company with 12 dispatched technicians. 24/7 emergency response for plumbing failures, water heaters, and major appliances.',
      specialties: ['Plumbing', 'Appliances', 'AC Maintenance'],
      coverageAreas: ['Chamkarmon', 'Sen Sok'],
      serviceArea: 'Chamkarmon, Sen Sok, Phnom Penh',
      categoryIds: ['cat-plumbing', 'cat-appliance', 'cat-ac'],
      rating: 4.8,
      reviewCount: 86,
      completedJobs: 320,
      hourlyRate: 20.0,
      isAvailable: true,
      phone: '+85511223344',
      email: 'company@test.com',
      status: 'active',
    ),
    // Pending verification providers for Admin Review & Approval (ADM-1 / ADM-2 / SCRUM-94)
    const ProviderModel(
      id: 'prov-pending-sokha',
      name: 'Sokha Pich',
      type: ProviderType.independent,
      description: 'Residential Split AC & Ventilation Technician',
      bio:
          'Independent AC repair technician with 5 years of field experience in Sen Sok and Toul Kork. Submitted national ID and trade certificate for platform review.',
      specialties: [
        'Split AC Chemical Wash',
        'Capacitor & Fan Motor Repair',
        'Drainage Line Unblocking',
      ],
      coverageAreas: ['Sen Sok', 'Toul Kork'],
      serviceArea: 'Sen Sok, Toul Kork, Phnom Penh',
      categoryIds: ['cat-ac'],
      yearsExperience: 5,
      hourlyRate: 16.0,
      isAvailable: true,
      phone: '+855 96 445 566',
      email: 'sokha.pich@servicepilot.kh',
      isVerified: false,
      status: 'pending_verification',
    ),
    const ProviderModel(
      id: 'prov-pending-mekong-co',
      name: 'Channary Rath',
      businessName: 'Mekong Home Repair Co., Ltd.',
      type: ProviderType.company,
      description: 'Licensed Plumbing & Electrical Maintenance Company',
      bio:
          'Phnom Penh home maintenance company with 6 full-time technicians covering Chamkarmon and Boeung Keng Kang. Business registration submitted for verification.',
      specialties: [
        'Emergency Pipe Leak Repair',
        'Breaker Panel Upgrades',
        'Water Heater Installation',
      ],
      coverageAreas: ['Chamkarmon', 'Boeung Keng Kang'],
      serviceArea: 'Chamkarmon, Boeung Keng Kang, Phnom Penh',
      categoryIds: ['cat-plumbing', 'cat-electrical'],
      yearsExperience: 4,
      hourlyRate: 22.0,
      isAvailable: true,
      phone: '+855 23 555 789',
      email: 'contact@mekonghomerepair.kh',
      isVerified: false,
      status: 'pending_verification',
    ),
  ];

  @override
  Future<List<ProviderModel>> getProviders({
    String? categoryId,
    bool activeOnly = true,
  }) async {
    return _providers.where((p) {
      if (activeOnly && !p.isApprovedAndActive) return false;
      if (categoryId != null && !p.categoryIds.contains(categoryId)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<ProviderModel>> getProvidersByCategory(String categoryId) {
    return getProviders(categoryId: categoryId, activeOnly: true);
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
    final clean = query.trim().toLowerCase();
    final base = await getProviders(categoryId: categoryId);
    if (clean.isEmpty) return base;

    return base.where((p) {
      final matchName = p.name.toLowerCase().contains(clean);
      final matchDesc = p.description.toLowerCase().contains(clean);
      final matchBio = p.bio.toLowerCase().contains(clean);
      final matchSpecialty =
          p.specialties.any((s) => s.toLowerCase().contains(clean));
      final matchArea =
          p.coverageAreas.any((a) => a.toLowerCase().contains(clean));

      return matchName ||
          matchDesc ||
          matchBio ||
          matchSpecialty ||
          matchArea;
    }).toList();
  }

  @override
  Future<List<ProviderModel>> getPendingProviders({
    required UserModel? actor,
  }) async {
    if (actor == null || !actor.isAdmin) {
      throw UnauthorizedProviderApprovalException(
        userId: actor?.id,
        role: actor?.role.value,
      );
    }

    return List.unmodifiable(
      _providers.where((p) => p.isPendingVerification),
    );
  }

  @override
  Future<ProviderModel> approveProvider({
    required String providerId,
    required UserModel? actor,
  }) async {
    if (actor == null || !actor.isAdmin) {
      throw UnauthorizedProviderApprovalException(
        providerId: providerId,
        userId: actor?.id,
        role: actor?.role.value,
      );
    }

    final index = _providers.indexWhere((p) => p.id == providerId);
    if (index == -1) {
      throw ProviderNotFoundException(providerId);
    }

    final current = _providers[index];
    if (!current.isPendingVerification) {
      throw InvalidProviderApprovalStateException(
        providerId: providerId,
        currentStatus: current.status,
      );
    }

    final approved = current.copyWith(
      status: 'active',
      isVerified: true,
      updatedAt: DateTime.now(),
    );
    _providers[index] = approved;
    return approved;
  }

  @override
  Future<void> seedInitialProviders() async {
    // In-memory implementation is a no-op
  }
}
