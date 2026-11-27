import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';

/// The pricing structure for a service offering.
///
/// Implements OFFER-2 (SCRUM-77 / SCRUM-118).
enum OfferingPricingMode {
  fixed,
  quoteRequired;

  String get value {
    switch (this) {
      case OfferingPricingMode.fixed:
        return 'fixed';
      case OfferingPricingMode.quoteRequired:
        return 'quote_required';
    }
  }

  static OfferingPricingMode fromValue(String? value) {
    if (value == 'quote_required' ||
        value == 'quoteRequired' ||
        value == 'quote') {
      return OfferingPricingMode.quoteRequired;
    }
    return OfferingPricingMode.fixed;
  }
}

/// Represents a distinct service offering published by an independent technician
/// or service company.
///
/// Corresponds to US OFFER-2 (SCRUM-77) and subtasks SCRUM-118, SCRUM-119, SCRUM-120.
class OfferingModel {
  final String id;
  final String providerId;
  final String providerName;
  final ProviderType providerType;
  final String categoryId;
  final String categoryName;
  final String title;
  final String description;
  final OfferingPricingMode pricingMode;
  final double? price;
  final String? unit;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OfferingModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    this.providerType = ProviderType.independent,
    required this.categoryId,
    this.categoryName = '',
    required this.title,
    required this.description,
    required this.pricingMode,
    double? price,
    this.unit,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  }) : price = pricingMode == OfferingPricingMode.quoteRequired ? null : price;

  /// True if this offering requires homeowners to request a custom quote.
  bool get isQuoteRequired => pricingMode == OfferingPricingMode.quoteRequired;

  /// True if this offering has a standard fixed price.
  bool get isFixedPrice => pricingMode == OfferingPricingMode.fixed;

  static bool isValidFixedPrice(double? price) {
    if (price == null || !price.isFinite || price <= 0) return false;
    final cents = price * 100;
    return cents.isFinite && cents.roundToDouble() / 100 == price;
  }

  /// Guard to prevent quote-required offerings from entering standard cart checkout.
  bool get canAddToCart => isFixedPrice;

  /// Whether this offering initiates a quote request flow.
  bool get requiresQuoteIntake => isQuoteRequired;

  /// Human-readable pricing display string.
  String get priceDisplay {
    if (isQuoteRequired) {
      return 'Quote Required';
    }
    final formattedPrice = '\$${(price ?? 0.0).toStringAsFixed(2)}';
    if (unit != null && unit!.trim().isNotEmpty) {
      return '$formattedPrice / $unit';
    }
    return formattedPrice;
  }

  factory OfferingModel.fromMap(Map<String, dynamic> data, [String? id]) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      return null;
    }

    return OfferingModel(
      id: id ?? (data['id'] as String? ?? ''),
      providerId: data['providerId'] as String? ?? '',
      providerName: data['providerName'] as String? ?? '',
      providerType: ProviderTypeExtension.fromValue(
        data['providerType'] as String?,
      ),
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      pricingMode: OfferingPricingMode.fromValue(data['pricingMode'] as String?),
      price: (data['price'] as num?)?.toDouble(),
      unit: data['unit'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  factory OfferingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OfferingModel.fromMap(data, doc.id);
  }

  factory OfferingModel.fromJson(Map<String, dynamic> json) =>
      OfferingModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'providerName': providerName,
      'providerType': providerType.value,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'title': title,
      'description': description,
      'pricingMode': pricingMode.value,
      'price': isFixedPrice ? price : null,
      'unit': unit,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  OfferingModel copyWith({
    String? id,
    String? providerId,
    String? providerName,
    ProviderType? providerType,
    String? categoryId,
    String? categoryName,
    String? title,
    String? description,
    OfferingPricingMode? pricingMode,
    double? price,
    String? unit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final effectiveMode = pricingMode ?? this.pricingMode;
    return OfferingModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerType: providerType ?? this.providerType,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      title: title ?? this.title,
      description: description ?? this.description,
      pricingMode: effectiveMode,
      price: effectiveMode == OfferingPricingMode.quoteRequired
          ? null
          : (price ?? this.price),
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
