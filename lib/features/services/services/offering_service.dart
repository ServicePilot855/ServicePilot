import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';

/// Contract for service offering management and catalog operations.
///
/// Implements US OFFER-2 (SCRUM-77 / SCRUM-118).
abstract class IOfferingService {
  /// Fetches offerings, optionally filtered by category, provider, and active status.
  Future<List<OfferingModel>> getOfferings({
    String? categoryId,
    String? providerId,
    bool activeOnly = true,
  });

  /// Fetches a single offering by its unique ID.
  Future<OfferingModel?> getOfferingById(String id);

  /// Publishes a new offering on behalf of an authorized provider.
  Future<OfferingModel> createOffering(OfferingModel offering);

  /// Updates an existing offering.
  Future<OfferingModel> updateOffering(OfferingModel offering);

  /// Deletes an offering by ID.
  Future<void> deleteOffering(String id);
}

/// In-memory and testable implementation of [IOfferingService].
class OfferingService implements IOfferingService {
  final List<OfferingModel> _offerings;

  OfferingService({List<OfferingModel>? initialOfferings})
      : _offerings = initialOfferings != null
            ? List.of(initialOfferings)
            : List.of(defaultOfferings);

  /// Initial catalog offerings including standard fixed-price and quote-required offerings.
  static final List<OfferingModel> defaultOfferings = [
    const OfferingModel(
      id: 'offering-dara-wash',
      providerId: 'prov-dara-ac',
      providerName: 'Dara Chhum',
      providerType: ProviderType.independent,
      categoryId: 'cat-ac',
      categoryName: 'Air Conditioner Repair & Care',
      title: 'Split Unit Deep Coil Wash',
      description:
          'Comprehensive high-pressure coil wash and drain unclogging.',
      pricingMode: OfferingPricingMode.fixed,
      price: 20.0,
      unit: 'unit',
      isActive: true,
    ),
    const OfferingModel(
      id: 'offering-dara-pcb-quote',
      providerId: 'prov-dara-ac',
      providerName: 'Dara Chhum',
      providerType: ProviderType.independent,
      categoryId: 'cat-ac',
      categoryName: 'Air Conditioner Repair & Care',
      title: 'Inverter Mainboard & PCB Replacement',
      description:
          'Diagnostics and micro-soldering or full PCB replacement for inverter split ACs. Price depends on brand availability and board model.',
      pricingMode: OfferingPricingMode.quoteRequired,
      price: null,
      isActive: true,
    ),
    const OfferingModel(
      id: 'offering-khmer-vrv-quote',
      providerId: 'prov-khmer-cool',
      providerName: 'Khmer Cool Aircon & Home Care Co., Ltd.',
      providerType: ProviderType.company,
      categoryId: 'cat-ac',
      categoryName: 'Air Conditioner Repair & Care',
      title: 'Commercial Central & VRV Duct Inspection',
      description:
          'Full-scale industrial HVAC engineering assessment, airflow balancing, and duct cleaning. Requires on-site quote assessment.',
      pricingMode: OfferingPricingMode.quoteRequired,
      price: null,
      isActive: true,
    ),
    const OfferingModel(
      id: 'offering-sopheap-leak-fix',
      providerId: 'prov-sopheap-plumbing',
      providerName: 'Sopheap Heng',
      providerType: ProviderType.independent,
      categoryId: 'cat-plumbing',
      categoryName: 'Plumbing & Drainage',
      title: 'Underground Pipe Leak Sonar Inspection',
      description:
          'Advanced ultrasonic acoustic detection for concealed underground water line breaks.',
      pricingMode: OfferingPricingMode.quoteRequired,
      price: null,
      isActive: true,
    ),
  ];

  @override
  Future<List<OfferingModel>> getOfferings({
    String? categoryId,
    String? providerId,
    bool activeOnly = true,
  }) async {
    return _offerings.where((offering) {
      if (activeOnly && !offering.isActive) return false;
      if (categoryId != null && offering.categoryId != categoryId) return false;
      if (providerId != null && offering.providerId != providerId) return false;
      return true;
    }).toList();
  }

  @override
  Future<OfferingModel?> getOfferingById(String id) async {
    try {
      return _offerings.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<OfferingModel> createOffering(OfferingModel offering) async {
    if (offering.isFixedPrice &&
        !OfferingModel.isValidFixedPrice(offering.price)) {
      throw ArgumentError.value(offering.price, 'price', 'Invalid fixed price');
    }
    // Defensive check: Quote-required offerings must not hold fixed checkout prices
    final sanitized =
        offering.isQuoteRequired ? offering.copyWith(price: null) : offering;

    _offerings.add(sanitized);
    return sanitized;
  }

  @override
  Future<OfferingModel> updateOffering(OfferingModel offering) async {
    if (offering.isFixedPrice &&
        !OfferingModel.isValidFixedPrice(offering.price)) {
      throw ArgumentError.value(offering.price, 'price', 'Invalid fixed price');
    }
    final index = _offerings.indexWhere((o) => o.id == offering.id);
    if (index == -1) {
      throw Exception('Offering with ID ${offering.id} not found');
    }
    final sanitized = OfferingModel.fromMap({
      ..._offerings[index].toMap(),
      ...offering.editableFields,
      'updatedAt': (offering.updatedAt ?? DateTime.now()).toIso8601String(),
    });

    _offerings[index] = sanitized;
    return sanitized;
  }

  @override
  Future<void> deleteOffering(String id) async {
    _offerings.removeWhere((o) => o.id == id);
  }
}
