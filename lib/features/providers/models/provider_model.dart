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
    if (value == 'company') return ProviderType.company;
    return ProviderType.independent;
  }
}

/// Represents a verified service provider in the ServicePilot platform.
///
/// Corresponds to US-10 (SCRUM-55) & US-11 (SCRUM-54).
class ProviderModel {
  final String id;
  final String name;
  final ProviderType type;
  final String description;
  final String bio;
  final List<String> specialties;
  final List<String> coverageAreas;
  final List<String> categoryIds;
  final double rating;
  final int reviewCount;
  final int completedJobsCount;
  final int yearsExperience;
  final bool isAvailable;
  final String? unavailableReason;
  final String status;
  final String? phoneNumber;
  final String? email;
  final double? startingPrice;
  final bool isVerified;

  const ProviderModel({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.bio,
    this.specialties = const [],
    this.coverageAreas = const [],
    this.categoryIds = const [],
    this.rating = 5.0,
    this.reviewCount = 0,
    this.completedJobsCount = 0,
    this.yearsExperience = 1,
    this.isAvailable = true,
    this.unavailableReason,
    this.status = 'active',
    this.phoneNumber,
    this.email,
    this.startingPrice,
    this.isVerified = true,
  });

  bool get isIndependent => type == ProviderType.independent;
  bool get isCompany => type == ProviderType.company;
  bool get isActive => status == 'active';

  /// Whether the customer can initiate a booking with this provider.
  bool get canAcceptBookings => isActive && isAvailable;

  String get typeDisplayName => type.displayName;
  String get formattedRating => rating.toStringAsFixed(1);
  String get formattedCoverageAreas => coverageAreas.join(', ');

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ProviderTypeExtension.fromValue(json['type'] as String?),
      description: json['description'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      coverageAreas: (json['coverageAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      categoryIds: (json['categoryIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      completedJobsCount: (json['completedJobsCount'] as num?)?.toInt() ?? 0,
      yearsExperience: (json['yearsExperience'] as num?)?.toInt() ?? 1,
      isAvailable: json['isAvailable'] as bool? ?? true,
      unavailableReason: json['unavailableReason'] as String?,
      status: json['status'] as String? ?? 'active',
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      startingPrice: (json['startingPrice'] as num?)?.toDouble(),
      isVerified: json['isVerified'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'description': description,
      'bio': bio,
      'specialties': specialties,
      'coverageAreas': coverageAreas,
      'categoryIds': categoryIds,
      'rating': rating,
      'reviewCount': reviewCount,
      'completedJobsCount': completedJobsCount,
      'yearsExperience': yearsExperience,
      'isAvailable': isAvailable,
      'unavailableReason': unavailableReason,
      'status': status,
      'phoneNumber': phoneNumber,
      'email': email,
      'startingPrice': startingPrice,
      'isVerified': isVerified,
    };
  }

  ProviderModel copyWith({
    String? id,
    String? name,
    ProviderType? type,
    String? description,
    String? bio,
    List<String>? specialties,
    List<String>? coverageAreas,
    List<String>? categoryIds,
    double? rating,
    int? reviewCount,
    int? completedJobsCount,
    int? yearsExperience,
    bool? isAvailable,
    String? unavailableReason,
    String? status,
    String? phoneNumber,
    String? email,
    double? startingPrice,
    bool? isVerified,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      coverageAreas: coverageAreas ?? this.coverageAreas,
      categoryIds: categoryIds ?? this.categoryIds,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      completedJobsCount: completedJobsCount ?? this.completedJobsCount,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      isAvailable: isAvailable ?? this.isAvailable,
      unavailableReason: unavailableReason ?? this.unavailableReason,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      startingPrice: startingPrice ?? this.startingPrice,
      isVerified: isVerified ?? this.isVerified,
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
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      isAvailable.hashCode ^
      status.hashCode;
}
