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

  /// Only set for [AppRole.companyTechnician] users.
  final String? companyId;
  final String? companyName;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.status,
    this.companyId,
    this.companyName,
  });

  bool get isActive => status == 'active';
  bool get isPendingVerification => status == 'pending_verification';

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    AppRole? role,
    String? status,
    String? companyId,
    String? companyName,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, email: $email, role: ${role.value})';
}
