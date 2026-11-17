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

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String? ?? 'build',
      providerCount: (json['providerCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      popularServices: (json['popularServices'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
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
