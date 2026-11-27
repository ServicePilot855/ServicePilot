import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Agreed appointment date & time confirmed by the provider (BOOK-2 / SCRUM-104).
  final DateTime? confirmedAppointmentAt;
  final DateTime? confirmedAt;
  final String? confirmedBy;

  /// Reason the provider gave for declining the request (BOOK-3 / SCRUM-105).
  final String? declinedReason;

  /// Map pin the customer dropped for the repair address, if any.
  final double? latitude;
  final double? longitude;

  /// Download links of the problem photos the customer attached.
  final List<String> photoUrls;

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
    this.confirmedAppointmentAt,
    this.confirmedAt,
    this.confirmedBy,
    this.declinedReason,
    this.latitude,
    this.longitude,
    this.photoUrls = const [],
  });

  /// Whether the customer pinned the address on the map.
  bool get hasLocation => latitude != null && longitude != null;

  /// Whether this booking's current status permits customer cancellation.
  ///
  /// Only `Pending`, `Assigned`, and `Confirmed` bookings can be cancelled.
  bool get canBeCancelled => status.canBeCancelled;

  /// Whether [userId] is the customer who created this booking.
  bool isOwnedBy(String userId) => customerId == userId;

  /// Whether [targetProviderId] is the provider this booking is addressed to.
  bool isOwnedByProvider(String targetProviderId) =>
      providerId == targetProviderId;

  /// Whether this booking is in an eligible state for provider confirmation.
  ///
  /// Implements BOOK-2 (SCRUM-104): cancelled, declined, completed,
  /// in-progress, or already confirmed bookings cannot be confirmed.
  bool get canBeConfirmed =>
      status == BookingStatus.pending || status == BookingStatus.assigned;

  /// Whether [targetProviderId] is authorized to confirm this booking now.
  bool canBeConfirmedBy(String targetProviderId) =>
      isOwnedByProvider(targetProviderId) && canBeConfirmed;

  /// US-14 (SCRUM-45) AC:
  /// Only the customer who created the booking can cancel it, and only when
  /// its status is Pending, Assigned, or Confirmed.
  bool canBeCancelledBy(String userId) => isOwnedBy(userId) && canBeCancelled;

  /// Whether the provider may decline this request (BOOK-3 / SCRUM-105):
  /// only an owned `Pending` request can be declined.
  bool canBeDeclinedBy(String targetProviderId) =>
      isOwnedByProvider(targetProviderId) &&
      status == BookingStatus.pending;

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
      confirmedAppointmentAt: json['confirmedAppointmentAt'] != null
          ? DateTime.tryParse(json['confirmedAppointmentAt'] as String)
          : null,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'] as String)
          : null,
      confirmedBy: json['confirmedBy'] as String?,
      declinedReason: json['declinedReason'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
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
      if (confirmedAppointmentAt != null)
        'confirmedAppointmentAt': confirmedAppointmentAt!.toIso8601String(),
      if (confirmedAt != null) 'confirmedAt': confirmedAt!.toIso8601String(),
      if (confirmedBy != null) 'confirmedBy': confirmedBy,
      if (declinedReason != null) 'declinedReason': declinedReason,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
    };
  }

  /// Document for the Firestore `bookings` collection.
  ///
  /// Uses the field names `firestore.rules` accepts (`categoryName`,
  /// `serviceType`, `appointmentDate`, `technicianId`, `technicianName`),
  /// which differ from [toJson]. Technicians can only read a booking through
  /// `technicianId`, so the names matter. The map pin is a `GeoPoint` in
  /// `location`; photo links go in `photos`.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'customerId': customerId,
      'providerId': providerId,
      'providerName': providerName,
      'categoryName': serviceCategory,
      'serviceType': serviceTitle,
      'description': description,
      'address': address,
      'appointmentDate': Timestamp.fromDate(preferredDateTime),
      'status': status.value,
      'totalPrice': totalPrice,
      if (assignedTechnicianId != null) 'technicianId': assignedTechnicianId,
      if (assignedTechnicianName != null)
        'technicianName': assignedTechnicianName,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      if (cancelledBy != null) 'cancelledBy': cancelledBy,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (confirmedAppointmentAt != null)
        'confirmedAppointmentAt': Timestamp.fromDate(confirmedAppointmentAt!),
      if (confirmedAt != null) 'confirmedAt': Timestamp.fromDate(confirmedAt!),
      if (confirmedBy != null) 'confirmedBy': confirmedBy,
      if (declinedReason != null) 'declinedReason': declinedReason,
      if (hasLocation) 'location': GeoPoint(latitude!, longitude!),
      if (photoUrls.isNotEmpty) 'photos': photoUrls,
    };
  }

  /// Reads a booking written by [toFirestore]. Dates may be Firestore
  /// timestamps or ISO strings (both are allowed by the rules).
  factory BookingModel.fromFirestore(
      String documentId, Map<String, dynamic> data) {
    return BookingModel(
      id: documentId,
      customerId: data['customerId'] as String? ?? '',
      providerId: data['providerId'] as String? ?? '',
      providerName: data['providerName'] as String? ?? 'Service Provider',
      serviceCategory: data['categoryName'] as String? ?? 'General Repair',
      serviceTitle: data['serviceType'] as String? ??
          data['categoryName'] as String? ??
          'Repair Service',
      description:
          data['description'] as String? ?? data['notes'] as String? ?? '',
      address: data['address'] as String? ?? '',
      preferredDateTime: _readDate(data['appointmentDate']) ?? DateTime.now(),
      status: BookingStatusExtension.fromValue(data['status'] as String?),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ??
          (data['price'] as num?)?.toDouble() ??
          0.0,
      assignedTechnicianId: data['technicianId'] as String?,
      assignedTechnicianName: data['technicianName'] as String?,
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(data['updatedAt']),
      cancelledAt: _readDate(data['cancelledAt']),
      cancelledBy: data['cancelledBy'] as String?,
      cancellationReason: data['cancellationReason'] as String?,
      confirmedAppointmentAt: _readDate(data['confirmedAppointmentAt']),
      confirmedAt: _readDate(data['confirmedAt']),
      confirmedBy: data['confirmedBy'] as String?,
      declinedReason: data['declinedReason'] as String?,
      latitude: (data['location'] as GeoPoint?)?.latitude,
      longitude: (data['location'] as GeoPoint?)?.longitude,
      photoUrls: (data['photos'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
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
    bool clearAssignment = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? cancellationReason,
    DateTime? confirmedAppointmentAt,
    DateTime? confirmedAt,
    String? confirmedBy,
    String? declinedReason,
    bool clearDeclinedReason = false,
    double? latitude,
    double? longitude,
    List<String>? photoUrls,
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
      assignedTechnicianId: clearAssignment
          ? null
          : assignedTechnicianId ?? this.assignedTechnicianId,
      assignedTechnicianName: clearAssignment
          ? null
          : assignedTechnicianName ?? this.assignedTechnicianName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      confirmedAppointmentAt:
          confirmedAppointmentAt ?? this.confirmedAppointmentAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      declinedReason: clearDeclinedReason
          ? null
          : declinedReason ?? this.declinedReason,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrls: photoUrls ?? this.photoUrls,
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
        other.cancelledAt == cancelledAt &&
        other.confirmedAppointmentAt == confirmedAppointmentAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        customerId,
        providerId,
        status,
        updatedAt,
        cancelledAt,
        confirmedAppointmentAt,
      );
}
