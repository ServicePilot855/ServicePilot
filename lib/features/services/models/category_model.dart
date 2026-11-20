import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Represents a home repair and maintenance service category in ServicePilot.
///
/// Corresponds to US-09 (SCRUM-41).
class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int providerCount;
  final bool isActive;
  final List<String> popularServices;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.providerCount = 0,
    this.isActive = true,
    this.popularServices = const [],
  });

  /// Whether this category currently has verified providers ready for booking.
  bool get hasAvailableProviders => providerCount > 0;

  /// Helper to map the string icon name to a Material icon.
  IconData get iconData {
    switch (iconName) {
      case 'ac_unit':
      case 'air_conditioner':
        return Icons.ac_unit_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrical_services':
      case 'bolt':
        return Icons.bolt_rounded;
      case 'home_repair_service':
      case 'appliance':
        return Icons.kitchen_rounded;
      case 'cleaning_services':
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'construction':
      case 'tools':
        return Icons.handyman_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  factory CategoryModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return CategoryModel(
      id: id ?? (data['id'] as String? ?? ''),
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      iconName: data['iconName'] as String? ?? 'build',
      providerCount: (data['providerCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      popularServices: (data['popularServices'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel.fromMap(data, doc.id);
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      CategoryModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'providerCount': providerCount,
      'isActive': isActive,
      'popularServices': popularServices,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    int? providerCount,
    bool? isActive,
    List<String>? popularServices,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      providerCount: providerCount ?? this.providerCount,
      isActive: isActive ?? this.isActive,
      popularServices: popularServices ?? this.popularServices,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
