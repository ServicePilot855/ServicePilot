import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';

/// Persisted homeowner quote request tied to a quote-required offering and provider.
///
/// Implements QUOTE-1 (SCRUM-83) and aligns with QUOTE-2..7 and PLAN.md 4.8.
class QuoteRequestModel {
  const QuoteRequestModel({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.providerId,
    required this.providerName,
    required this.offeringId,
    required this.offeringTitle,
    this.categoryId = '',
    this.categoryName = '',
    required this.description,
    this.photoUrls = const [],
    this.status = QuoteStatus.requested,
    this.quotedPrice,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String customerId;
  final String? customerName;
  final String providerId;
  final String providerName;
  final String offeringId;
  final String offeringTitle;
  final String categoryId;
  final String categoryName;
  final String description;
  final List<String> photoUrls;
  final QuoteStatus status;
  final double? quotedPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool isOwnedByCustomer(String userId) => customerId == userId;

  bool isAddressedToProvider(String targetProviderId) =>
      providerId == targetProviderId;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'customerId': customerId,
      if (customerName != null && customerName!.trim().isNotEmpty)
        'customerName': customerName!.trim(),
      'providerId': providerId,
      'providerName': providerName,
      'offeringId': offeringId,
      'offeringTitle': offeringTitle,
      if (categoryId.isNotEmpty) 'categoryId': categoryId,
      if (categoryName.isNotEmpty) 'categoryName': categoryName,
      'description': description,
      if (photoUrls.isNotEmpty) 'photos': photoUrls,
      'status': status.value,
      if (quotedPrice != null) 'quotedPrice': quotedPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory QuoteRequestModel.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return QuoteRequestModel(
      id: documentId,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String?,
      providerId: data['providerId'] as String? ?? '',
      providerName: data['providerName'] as String? ?? 'Service Provider',
      offeringId: data['offeringId'] as String? ?? '',
      offeringTitle: data['offeringTitle'] as String? ?? 'Quote Service',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      photoUrls: _readStringList(data['photos'] ?? data['photoUrls']),
      status: QuoteStatusExtension.fromValue(data['status'] as String?),
      quotedPrice: (data['quotedPrice'] as num?)?.toDouble(),
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  QuoteRequestModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? providerId,
    String? providerName,
    String? offeringId,
    String? offeringTitle,
    String? categoryId,
    String? categoryName,
    String? description,
    List<String>? photoUrls,
    QuoteStatus? status,
    double? quotedPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuoteRequestModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      offeringId: offeringId ?? this.offeringId,
      offeringTitle: offeringTitle ?? this.offeringTitle,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
