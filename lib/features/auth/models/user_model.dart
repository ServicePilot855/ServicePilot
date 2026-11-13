import 'package:service_pilot/core/constants/app_roles.dart';

/// Represents an authenticated user in the ServicePilot platform.
///
/// Immutable data class — use [copyWith] to derive updated instances.
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final AppRole role;

  /// Account lifecycle status.
  /// Possible values: 'active', 'pending_verification', 'suspended'
  final String status;

  /// Service area / districts covered by the technician (max 300 chars).
  /// Required for [AppRole.independentProvider].
  final String? serviceArea;

  /// Only set for [AppRole.companyTechnician] users.
  final String? companyId;
  final String? companyName;

  /// Account creation timestamp.
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.status,
    this.serviceArea,
    this.companyId,
    this.companyName,
    this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isPendingVerification => status == 'pending_verification';
  bool get isSuspended => status == 'suspended';
  bool get isIndependentTechnician => role == AppRole.independentProvider;

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    AppRole? role,
    String? status,
    String? serviceArea,
    String? companyId,
    String? companyName,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      status: status ?? this.status,
      serviceArea: serviceArea ?? this.serviceArea,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.value,
      'status': status,
      if (serviceArea != null) 'serviceArea': serviceArea,
      if (companyId != null) 'companyId': companyId,
      if (companyName != null) 'companyName': companyName,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: AppRoleExtension.fromValue(json['role'] as String?),
      status: json['status'] as String? ?? 'active',
      serviceArea: json['serviceArea'] as String?,
      companyId: json['companyId'] as String?,
      companyName: json['companyName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'UserModel(id: $id, email: $email, role: ${role.value}, status: $status, serviceArea: $serviceArea)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.role == role &&
        other.status == status &&
        other.serviceArea == serviceArea &&
        other.companyId == companyId &&
        other.companyName == companyName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      fullName,
      email,
      phoneNumber,
      role,
      status,
      serviceArea,
      companyId,
      companyName,
    );
  }
}
