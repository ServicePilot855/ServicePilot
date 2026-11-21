import 'dart:async';
import 'package:service_pilot/features/providers/models/provider_model.dart';

/// Contract for administrative provider verification and review operations.
///
/// Corresponds to Sprint 3 SCRUM-93 (ADM-1: View pending provider applications).
abstract class IAdminProviderService {
  /// Fetches all providers with status == 'pending_verification'.
  Future<List<ProviderModel>> getPendingProviders();

  /// Real-time stream of pending providers for reactive review queue updates.
  Stream<List<ProviderModel>> watchPendingProviders();

  /// Fetches a single provider by ID.
  Future<ProviderModel?> getProviderById(String id);

  /// Updates a provider's verification status (e.g. 'active', 'rejected').
  Future<void> updateProviderStatus(String providerId, String status);
}

/// In-memory implementation of [IAdminProviderService] for development,
/// offline resilient testing, and widget test suites.
class AdminProviderService implements IAdminProviderService {
  final List<ProviderModel> _providers;
  final _controller = StreamController<List<ProviderModel>>.broadcast();

  AdminProviderService({List<ProviderModel>? initialProviders})
      : _providers = List<ProviderModel>.from(
          initialProviders ?? defaultPendingProviders,
        );

  /// Realistic demo pending provider applications across Phnom Penh.
  static final List<ProviderModel> defaultPendingProviders = [
    ProviderModel(
      id: 'prov-pending-sokunthea',
      name: 'Sokunthea Keo',
      businessName: 'Keo Electrical & Cooling',
      type: ProviderType.independent,
      description: 'Certified Electrician & Inverter AC Specialist',
      bio:
          'Over 6 years of residential electrical rewiring, safety breaker installations, and energy-efficient inverter diagnostics across Phnom Penh.',
      specialties: const [
        'Electrical Wiring & Breakers',
        'Inverter AC Diagnostics',
        'Chemical Coil Wash',
        'Emergency Power Restoration',
      ],
      coverageAreas: const ['Toul Kork', 'Daun Penh', 'Sen Sok'],
      serviceArea: 'Toul Kork, Daun Penh, Sen Sok',
      categoryIds: const ['cat-electrical', 'cat-ac'],
      hourlyRate: 18.0,
      phone: '+855 12 345 678',
      email: 'sokunthea.keo@example.com',
      status: 'pending_verification',
      isVerified: false,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ProviderModel(
      id: 'prov-pending-clean-cool',
      name: 'Phnom Penh Clean & Cool Co.',
      businessName: 'PP Clean & Cool Services Co., Ltd.',
      type: ProviderType.company,
      description:
          'Commercial and residential HVAC & sanitary plumbing contractor',
      bio:
          'Licensed enterprise provider with a fleet of 12 certified technicians serving major commercial buildings and boreys throughout Phnom Penh.',
      specialties: const [
        'Commercial VRV / Chiller Service',
        'High-Pressure Pipe Jetting',
        'Water Tank Sanitization',
        'Multi-unit AC Maintenance',
      ],
      coverageAreas: const ['Chamkarmon', 'BKK1', 'Chroy Changvar', 'Sen Sok'],
      serviceArea: 'Chamkarmon, BKK1, Chroy Changvar, Sen Sok',
      categoryIds: const ['cat-ac', 'cat-plumbing'],
      hourlyRate: 25.0,
      phone: '+855 23 888 999',
      email: 'contact@cleanandcool.com.kh',
      status: 'pending_verification',
      isVerified: false,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
  ];

  @override
  Future<List<ProviderModel>> getPendingProviders() async {
    return _providers.where((p) => p.status == 'pending_verification').toList();
  }

  @override
  Stream<List<ProviderModel>> watchPendingProviders() async* {
    yield await getPendingProviders();
    yield* _controller.stream;
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
  Future<void> updateProviderStatus(String providerId, String status) async {
    final idx = _providers.indexWhere((p) => p.id == providerId);
    if (idx != -1) {
      _providers[idx] = _providers[idx].copyWith(
        status: status,
        isVerified: status == 'active',
        updatedAt: DateTime.now(),
      );
      _controller.add(await getPendingProviders());
    }
  }

  void dispose() {
    _controller.close();
  }
}
