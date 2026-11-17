import 'package:service_pilot/features/services/models/category_model.dart';

/// Contract for category retrieval and search operations.
///
/// Corresponds to US-09 (SCRUM-41).
abstract class ICategoryService {
  /// Fetches all active service categories.
  Future<List<CategoryModel>> getCategories();

  /// Fetches a single category by its unique ID.
  Future<CategoryModel?> getCategoryById(String id);

  /// Searches categories by query term (matches name or description).
  Future<List<CategoryModel>> searchCategories(String query);
}

/// Production and testable implementation of [ICategoryService].
class CategoryService implements ICategoryService {
  final List<CategoryModel> _categories;

  CategoryService({List<CategoryModel>? initialCategories})
      : _categories = initialCategories ?? defaultCategories;

  /// Default categories tailored for Phnom Penh home services per ServicePilot specifications.
  static final List<CategoryModel> defaultCategories = [
    const CategoryModel(
      id: 'cat-ac',
      name: 'Air Conditioner Repair & Care',
      description:
          'Deep chemical wash, refrigerant gas refill, compressor inspection, and leak fixes.',
      iconName: 'ac_unit',
      providerCount: 12,
      popularServices: ['Deep Cleaning', 'Gas Top-up', 'Water Leak Fix', 'Installation'],
    ),
    const CategoryModel(
      id: 'cat-plumbing',
      name: 'Plumbing & Drainage',
      description:
          'Pipe leak repairs, bathroom fixtures, pump installation, and drain unblocking.',
      iconName: 'plumbing',
      providerCount: 9,
      popularServices: ['Leak Detection', 'Pipe Replacement', 'Toilet Repair', 'Water Heater'],
    ),
    const CategoryModel(
      id: 'cat-electrical',
      name: 'Electrical & Wiring',
      description:
          'Short circuit diagnosis, breaker replacement, smart switch setup, and fixture installation.',
      iconName: 'bolt',
      providerCount: 8,
      popularServices: ['Short Circuit Fix', 'Ceiling Fan Install', 'Lighting', 'Breaker Box'],
    ),
    const CategoryModel(
      id: 'cat-appliance',
      name: 'Appliance Repair',
      description:
          'Diagnostics and repair for refrigerators, washing machines, microwaves, and ovens.',
      iconName: 'appliance',
      providerCount: 7,
      popularServices: ['Washing Machine', 'Refrigerator', 'Microwave', 'Induction Cooker'],
    ),
    const CategoryModel(
      id: 'cat-cleaning',
      name: 'Home & Room Cleaning',
      description:
          'Comprehensive deep cleaning, move-in/move-out sanitize, and upholstery vacuuming.',
      iconName: 'cleaning',
      providerCount: 15,
      popularServices: ['Deep Clean', 'Sofa Washing', 'Move-in Sanitization', 'Post-renovation'],
    ),
    const CategoryModel(
      id: 'cat-locksmith',
      name: 'Locksmith & Security',
      description:
          'Door lock replacement, emergency lockout assistance, and digital lock setup.',
      iconName: 'tools',
      providerCount: 0, // Demonstrates empty-state requirement in US-09 AC
      popularServices: ['Emergency Lockout', 'Key Duplication', 'Smart Lock'],
    ),
  ];

  @override
  Future<List<CategoryModel>> getCategories() async {
    // Return all active categories
    return List.unmodifiable(
      _categories.where((cat) => cat.isActive),
    );
  }

  @override
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      return _categories.firstWhere((cat) => cat.id == id && cat.isActive);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CategoryModel>> searchCategories(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return getCategories();
    }

    return _categories.where((cat) {
      if (!cat.isActive) return false;
      final matchName = cat.name.toLowerCase().contains(cleanQuery);
      final matchDesc = cat.description.toLowerCase().contains(cleanQuery);
      final matchServices = cat.popularServices.any(
        (s) => s.toLowerCase().contains(cleanQuery),
      );
      return matchName || matchDesc || matchServices;
    }).toList();
  }
}
