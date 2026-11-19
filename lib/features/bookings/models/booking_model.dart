import 'package:service_pilot/core/constants/booking_status.dart';

/// Represents a customer's repair service booking in ServicePilot.
///
/// Corresponds to US-12 (SCRUM-43), US-13 (SCRUM-44), US-14 (SCRUM-45), and US-15 (SCRUM-46).
class BookingModel {
  final String id;
  final String customerId;
  final String providerId;
  final String providerName;
  final String serviceCategory;
  final String serviceTitle;
  final String description;
  final String address;
  final DateTime preferredDateTime;
  final BookingStatus status;
  final double totalPrice;
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;

  const BookingModel({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.providerName,
    required this.serviceCategory,
    required this.serviceTitle,
    required this.description,
    required this.address,
    required this.preferredDateTime,
    this.status = BookingStatus.pending,
    this.totalPrice = 0.0,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    required this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
  });

  /// Whether this booking's current status permits customer cancellation.
  ///
  /// Only `Pending`, `Assigned`, and `Confirmed` bookings can be cancelled.
  bool get canBeCancelled => status.canBeCancelled;

  /// Whether [userId] is the customer who created this booking.
  bool isOwnedBy(String userId) => customerId == userId;

  /// US-14 (SCRUM-45) AC:
  /// Only the customer who created the booking can cancel it, and only when
  /// its status is Pending, Assigned, or Confirmed.
  bool canBeCancelledBy(String userId) => isOwnedBy(userId) && canBeCancelled;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      providerId: json['providerId'] as String,
      providerName: json['providerName'] as String? ?? 'Service Provider',
      serviceCategory: json['serviceCategory'] as String? ?? 'General Repair',
      serviceTitle:
          json['serviceTitle'] as String? ??
          json['serviceCategory'] as String? ??
          'Repair Service',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      preferredDateTime: DateTime.parse(json['preferredDateTime'] as String),
      status: BookingStatusExtension.fromValue(json['status'] as String?),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      assignedTechnicianId: json['assignedTechnicianId'] as String?,
      assignedTechnicianName: json['assignedTechnicianName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'] as String)
          : null,
      cancelledBy: json['cancelledBy'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'providerId': providerId,
      'providerName': providerName,
      'serviceCategory': serviceCategory,
      'serviceTitle': serviceTitle,
      'description': description,
      'address': address,
      'preferredDateTime': preferredDateTime.toIso8601String(),
      'status': status.value,
      'totalPrice': totalPrice,
      if (assignedTechnicianId != null)
        'assignedTechnicianId': assignedTechnicianId,
      if (assignedTechnicianName != null)
        'assignedTechnicianName': assignedTechnicianName,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
      if (cancelledBy != null) 'cancelledBy': cancelledBy,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
    };
  }

  BookingModel copyWith({
    String? id,
    String? customerId,
    String? providerId,
    String? providerName,
    String? serviceCategory,
    String? serviceTitle,
    String? description,
    String? address,
    DateTime? preferredDateTime,
    BookingStatus? status,
    double? totalPrice,
    String? assignedTechnicianId,
    String? assignedTechnicianName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? cancellationReason,
  }) {
    return BookingModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      description: description ?? this.description,
      address: address ?? this.address,
      preferredDateTime: preferredDateTime ?? this.preferredDateTime,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      assignedTechnicianName:
          assignedTechnicianName ?? this.assignedTechnicianName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingModel &&
        other.id == id &&
        other.customerId == customerId &&
        other.providerId == providerId &&
        other.status == status &&
        other.updatedAt == updatedAt &&
        other.cancelledAt == cancelledAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, customerId, providerId, status, updatedAt, cancelledAt);
}
