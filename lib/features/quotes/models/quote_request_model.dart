import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';

/// Persisted homeowner quote request tied to a quote-required offering and provider.
///
/// Implements QUOTE-1 (SCRUM-83) and aligns with QUOTE-2..7 and PLAN.md 4.8.
/// QUOTE-3 (SCRUM-85) adds the provider's price ([quotedPrice], [quotedAt]),
/// QUOTE-4 (SCRUM-86) the homeowner's approval ([approvedPrice],
/// [approvedAt]) and QUOTE-5 (SCRUM-87) the linked booking ([bookingId]).
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
    this.quotedAt,
    this.approvedPrice,
    this.approvedAt,
    this.bookingId,
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
  final DateTime? quotedAt;

  /// The amount the homeowner agreed to. Equals [quotedPrice] at approval.
  final double? approvedPrice;
  final DateTime? approvedAt;

  /// The Pending booking created from this approved quote, once booked.
  final String? bookingId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool isOwnedByCustomer(String userId) => customerId == userId;

  bool isAddressedToProvider(String targetProviderId) =>
      providerId == targetProviderId;

  /// QUOTE-3: only the addressed provider can price a `Requested` record.
  bool canBeQuotedBy(String targetProviderId) =>
      status == QuoteStatus.requested &&
      isAddressedToProvider(targetProviderId);

  /// QUOTE-4: only the requesting homeowner can approve a priced quote.
  bool canBeApprovedBy(String userId) =>
      status == QuoteStatus.quoted &&
      quotedPrice != null &&
      isOwnedByCustomer(userId);

  /// Whether a booking has already been created from this quote.
  bool get isBooked => bookingId != null && bookingId!.isNotEmpty;

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
      if (quotedAt != null) 'quotedAt': Timestamp.fromDate(quotedAt!),
      if (approvedPrice != null) 'approvedPrice': approvedPrice,
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (isBooked) 'bookingId': bookingId,
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
      quotedAt: _readDate(data['quotedAt']),
      approvedPrice: (data['approvedPrice'] as num?)?.toDouble(),
      approvedAt: _readDate(data['approvedAt']),
      bookingId: data['bookingId'] as String?,
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
    DateTime? quotedAt,
    double? approvedPrice,
    DateTime? approvedAt,
    String? bookingId,
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
      quotedAt: quotedAt ?? this.quotedAt,
      approvedPrice: approvedPrice ?? this.approvedPrice,
      approvedAt: approvedAt ?? this.approvedAt,
      bookingId: bookingId ?? this.bookingId,
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

/// Why a provider's price entry was refused (QUOTE-3 / SCRUM-85).
enum QuotePriceError { required, invalid }

/// Price input rules for a quote. They match the fixed-price listing rule:
/// an amount in USD above zero with at most two decimal places.
class QuotePriceValidator {
  QuotePriceValidator._();

  /// Parses [raw] from the price field. Returns null when it is not a number.
  static double? parse(String? raw) {
    final text = raw?.trim().replaceFirst(RegExp(r'^\$'), '').trim() ?? '';
    return double.tryParse(text);
  }

  static QuotePriceError? validateInput(String? raw) {
    if (raw == null || raw.trim().isEmpty) return QuotePriceError.required;
    return validate(parse(raw));
  }

  static QuotePriceError? validate(double? price) {
    if (price == null) return QuotePriceError.required;
    return OfferingModel.isValidFixedPrice(price)
        ? null
        : QuotePriceError.invalid;
  }
}

/// `$85.00`: the format used for every quote amount in the app.
String formatQuoteAmount(double amount) => '\$${amount.toStringAsFixed(2)}';
