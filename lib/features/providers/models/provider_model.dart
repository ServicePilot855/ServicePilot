import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_pilot/core/constants/app_roles.dart';

/// Distinguishes between an independent technician and a repair company.
///
/// Corresponds to US-10 (SCRUM-55) and US-11 (SCRUM-54).
enum ProviderType {
  independent,
  company,
}

extension ProviderTypeExtension on ProviderType {
  String get displayName {
    switch (this) {
      case ProviderType.independent:
        return 'Independent Technician';
      case ProviderType.company:
        return 'Repair Company';
    }
  }

  String get value {
    switch (this) {
      case ProviderType.independent:
        return 'independent';
      case ProviderType.company:
        return 'company';
    }
  }

  static ProviderType fromValue(String? value) {
    if (value != null && value.toLowerCase().contains('company')) {
      return ProviderType.company;
    }
    return ProviderType.independent;
  }
}

/// Represents a verified repair & maintenance service provider in ServicePilot.
///
/// Supports both independent technicians and repair companies per US-10 (SCRUM-55) & US-11 (SCRUM-54).
class ProviderModel {
  final String id;
  final String name;
  final String? businessName;
  final ProviderType type;
  final String description;
  final String bio;
  final List<String> specialties;
  final List<String> coverageAreas;
  final String serviceArea;
  final List<String> categoryIds;
  final double? _recordedRating;
  final int? recordedReviewCount;
  final int completedJobs;
  final int yearsExperience;
  final double hourlyRate;
  final bool isAvailable;
  final String? unavailableReason;
  final String status; // 'active', 'pending_verification', 'suspended'
  final String phone;
  final String email;
  final bool isVerified;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProviderModel({
    required this.id,
    required this.name,
    this.businessName,
    this.type = ProviderType.independent,
    this.description = '',
    this.bio = '',
    this.specialties = const [],
    this.coverageAreas = const [],
    this.serviceArea = 'Phnom Penh',
    this.categoryIds = const [],
    double? rating,
    int? reviewCount,
    int completedJobs = 0,
    int? completedJobsCount,
    this.yearsExperience = 1,
    double hourlyRate = 15.0,
    double? startingPrice,
    this.isAvailable = true,
    this.unavailableReason,
    this.status = 'active',
    String phone = '',
    String? phoneNumber,
    this.email = '',
    this.isVerified = true,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  })  : _recordedRating = rating,
        recordedReviewCount = reviewCount,
        completedJobs = completedJobsCount ?? completedJobs,
        hourlyRate = startingPrice ?? hourlyRate,
        phone = phoneNumber ?? phone;

  /// Display title: uses [businessName] if available, otherwise [name].
  String get displayName =>
      (businessName != null && businessName!.trim().isNotEmpty)
          ? businessName!
          : name;

  /// Compatibility alias for Chhunhour's test suite and screens
  int get completedJobsCount => completedJobs;

  /// Compatibility alias for phone number
  String? get phoneNumber => phone.isNotEmpty ? phone : null;

  /// Compatibility alias for starting price
  double? get startingPrice => hourlyRate;

  /// AppRole mapping
  AppRole get appRole =>
      isCompany ? AppRole.company : AppRole.independentProvider;

  /// Whether the provider is an independent technician.
  bool get isIndependent => type == ProviderType.independent;

  /// Whether the provider is a registered service company.
  bool get isCompany => type == ProviderType.company;

  /// Whether the provider status is active.
  bool get isActive => status.toLowerCase() == 'active';

  /// Whether the provider is awaiting platform administrator verification (ADM-1 / ADM-2).
  bool get isPendingVerification =>
      status.toLowerCase() == 'pending_verification';

  /// Only active approved providers can be listed for customer booking (US-10 AC & ADM-2 AC).
  bool get isApprovedAndActive => isActive && isVerified;

  /// Whether the provider is currently available to accept new booking requests (US-11 AC).
  bool get canAcceptBookings => isApprovedAndActive && isAvailable;

  /// Label for the provider type badge.
  String get typeDisplayName => type.displayName;
  String get typeBadgeLabel => isCompany ? 'Company' : 'Independent';

  // Legacy defaults are separate from the values shown as customer evidence.
  double get rating => _recordedRating ?? 5.0;
  int get reviewCount => recordedReviewCount ?? 0;

  double? get customerRating {
    final score = _recordedRating;
    return reviewCount > 0 && score != null && score >= 1 && score <= 5
        ? score
        : null;
  }

  /// Formatted rating for callers using the legacy default.
  String get formattedRating => rating.toStringAsFixed(1);

  /// Formatted coverage areas (comma-separated)
  String get formattedCoverageAreas =>
      coverageAreas.isNotEmpty ? coverageAreas.join(', ') : serviceArea;

  factory ProviderModel.fromMap(Map<String, dynamic> data, String id) {
    final rawType = data['type'];
    final providerType = ProviderTypeExtension.fromValue(rawType?.toString());

    DateTime? createdDate;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      createdDate = rawCreated.toDate();
    } else if (rawCreated is String) {
      createdDate = DateTime.tryParse(rawCreated);
    }

    DateTime? updatedDate;
    final rawUpdated = data['updatedAt'];
    if (rawUpdated is Timestamp) {
      updatedDate = rawUpdated.toDate();
    } else if (rawUpdated is String) {
      updatedDate = DateTime.tryParse(rawUpdated);
    }

    final rawCoverage = data['coverageAreas'];
    List<String> coverage = [];
    if (rawCoverage is List) {
      coverage = rawCoverage.map((e) => e.toString()).toList();
    } else if (data['serviceArea'] != null) {
      coverage = [data['serviceArea'].toString()];
    }

    final rawSpecialties = data['specialties'];
    List<String> specs = [];
    if (rawSpecialties is List) {
      specs = rawSpecialties.map((e) => e.toString()).toList();
    }

    final rawRating = data['rating'];
    final rawCount = data['reviewCount'];
    final recordedCount = rawCount is num &&
            rawCount.isFinite &&
            rawCount >= 0 &&
            rawCount == rawCount.toInt()
        ? rawCount.toInt()
        : null;

    return ProviderModel(
      id: id,
      name: data['name'] as String? ?? 'Service Provider',
      businessName: data['businessName'] as String?,
      type: providerType,
      description: data['description'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      specialties: specs,
      coverageAreas: coverage,
      serviceArea: data['serviceArea'] as String? ??
          (coverage.isNotEmpty ? coverage.first : 'Phnom Penh'),
      categoryIds: (data['categoryIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      rating: rawRating is num ? rawRating.toDouble() : null,
      reviewCount: recordedCount,
      completedJobs: (data['completedJobs'] as num?)?.toInt() ??
          (data['completedJobsCount'] as num?)?.toInt() ??
          0,
      yearsExperience: (data['yearsExperience'] as num?)?.toInt() ?? 1,
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ??
          (data['startingPrice'] as num?)?.toDouble() ??
          15.0,
      isAvailable: data['isAvailable'] as bool? ?? true,
      unavailableReason: data['unavailableReason'] as String?,
      status: data['status'] as String? ?? 'active',
      phone: data['phone'] as String? ?? data['phoneNumber'] as String? ?? '',
      email: data['email'] as String? ?? '',
      isVerified: data['isVerified'] as bool? ?? true,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: createdDate,
      updatedAt: updatedDate,
    );
  }

  factory ProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProviderModel.fromMap(data, doc.id);
  }

  factory ProviderModel.fromJson(Map<String, dynamic> json) =>
      ProviderModel.fromMap(json, json['id'] as String? ?? '');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (businessName != null) 'businessName': businessName,
      'type': type.value,
      'description': description,
      'bio': bio,
      'specialties': specialties,
      'coverageAreas': coverageAreas,
      'serviceArea': serviceArea,
      'categoryIds': categoryIds,
      if (_recordedRating != null) 'rating': _recordedRating,
      if (recordedReviewCount != null) 'reviewCount': recordedReviewCount,
      'completedJobs': completedJobs,
      'completedJobsCount': completedJobs,
      'yearsExperience': yearsExperience,
      'hourlyRate': hourlyRate,
      'startingPrice': hourlyRate,
      'isAvailable': isAvailable,
      if (unavailableReason != null) 'unavailableReason': unavailableReason,
      'status': status,
      'phone': phone,
      'phoneNumber': phone,
      'email': email,
      'isVerified': isVerified,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  ProviderModel copyWith({
    String? id,
    String? name,
    String? businessName,
    ProviderType? type,
    String? description,
    String? bio,
    List<String>? specialties,
    List<String>? coverageAreas,
    String? serviceArea,
    List<String>? categoryIds,
    double? rating,
    int? reviewCount,
    int? completedJobs,
    int? completedJobsCount,
    int? yearsExperience,
    double? hourlyRate,
    double? startingPrice,
    bool? isAvailable,
    String? unavailableReason,
    String? status,
    String? phone,
    String? phoneNumber,
    String? email,
    bool? isVerified,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      type: type ?? this.type,
      description: description ?? this.description,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      coverageAreas: coverageAreas ?? this.coverageAreas,
      serviceArea: serviceArea ?? this.serviceArea,
      categoryIds: categoryIds ?? this.categoryIds,
      rating: rating ?? _recordedRating,
      reviewCount: reviewCount ?? recordedReviewCount,
      completedJobs: completedJobs ?? completedJobsCount ?? this.completedJobs,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      hourlyRate: hourlyRate ?? startingPrice ?? this.hourlyRate,
      isAvailable: isAvailable ?? this.isAvailable,
      unavailableReason: unavailableReason ?? this.unavailableReason,
      status: status ?? this.status,
      phone: phone ?? phoneNumber ?? this.phone,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          isAvailable == other.isAvailable &&
          isVerified == other.isVerified &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      isAvailable.hashCode ^
      isVerified.hashCode ^
      status.hashCode;
}
