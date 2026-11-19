import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_pilot/core/constants/app_roles.dart';

/// Represents a verified repair & maintenance service provider in ServicePilot.
///
/// Supports both independent technicians and repair companies per US-10 (SCRUM-55) & US-11 (SCRUM-54).
class ProviderModel {
  final String id;
  final String name;
  final String? businessName;
  final String email;
  final String phone;
  final AppRole type;
  final String status; // 'active', 'pending_verification', 'suspended'
  final String serviceArea;
  final List<String> categoryIds;
  final double rating;
  final int reviewCount;
  final int completedJobs;
  final double hourlyRate;
  final String bio;
  final bool isAvailable;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProviderModel({
    required this.id,
    required this.name,
    this.businessName,
    required this.email,
    required this.phone,
    required this.type,
    this.status = 'active',
    required this.serviceArea,
    required this.categoryIds,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.completedJobs = 0,
    this.hourlyRate = 15.0,
    this.bio = '',
    this.isAvailable = true,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
  });

  /// Display title: uses [businessName] if available, otherwise [name].
  String get displayName =>
      (businessName != null && businessName!.trim().isNotEmpty)
          ? businessName!
          : name;

  /// Whether the provider is an independent technician.
  bool get isIndependent => type == AppRole.independentProvider;

  /// Whether the provider is a registered service company.
  bool get isCompany => type == AppRole.company;

  /// Only active approved providers can be listed for customer booking (US-10 AC).
  bool get isApprovedAndActive => status.toLowerCase() == 'active';

  /// Whether the provider is currently available to accept new booking requests (US-11 AC).
  bool get canAcceptBookings => isApprovedAndActive && isAvailable;

  /// Label for the provider type badge.
  String get typeBadgeLabel => isCompany ? 'Company' : 'Independent';

  factory ProviderModel.fromMap(Map<String, dynamic> data, String id) {
    AppRole role = AppRole.independentProvider;
    final typeStr = data['type']?.toString().toLowerCase() ?? '';
    if (typeStr.contains('company')) {
      role = AppRole.company;
    }

    DateTime createdDate = DateTime.now();
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      createdDate = rawCreated.toDate();
    } else if (rawCreated is String) {
      createdDate = DateTime.tryParse(rawCreated) ?? DateTime.now();
    }

    DateTime? updatedDate;
    final rawUpdated = data['updatedAt'];
    if (rawUpdated is Timestamp) {
      updatedDate = rawUpdated.toDate();
    } else if (rawUpdated is String) {
      updatedDate = DateTime.tryParse(rawUpdated);
    }

    return ProviderModel(
      id: id,
      name: data['name'] as String? ?? 'Service Provider',
      businessName: data['businessName'] as String?,
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      type: role,
      status: data['status'] as String? ?? 'active',
      serviceArea: data['serviceArea'] as String? ?? 'Phnom Penh',
      categoryIds: (data['categoryIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      completedJobs: (data['completedJobs'] as num?)?.toInt() ?? 0,
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 15.0,
      bio: data['bio'] as String? ?? '',
      isAvailable: data['isAvailable'] as bool? ?? true,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: createdDate,
      updatedAt: updatedDate,
    );
  }

  factory ProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProviderModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (businessName != null) 'businessName': businessName,
      'email': email,
      'phone': phone,
      'type': type.name,
      'status': status,
      'serviceArea': serviceArea,
      'categoryIds': categoryIds,
      'rating': rating,
      'reviewCount': reviewCount,
      'completedJobs': completedJobs,
      'hourlyRate': hourlyRate,
      'bio': bio,
      'isAvailable': isAvailable,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  ProviderModel copyWith({
    String? id,
    String? name,
    String? businessName,
    String? email,
    String? phone,
    AppRole? type,
    String? status,
    String? serviceArea,
    List<String>? categoryIds,
    double? rating,
    int? reviewCount,
    int? completedJobs,
    double? hourlyRate,
    String? bio,
    bool? isAvailable,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      status: status ?? this.status,
      serviceArea: serviceArea ?? this.serviceArea,
      categoryIds: categoryIds ?? this.categoryIds,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      completedJobs: completedJobs ?? this.completedJobs,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      bio: bio ?? this.bio,
      isAvailable: isAvailable ?? this.isAvailable,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
