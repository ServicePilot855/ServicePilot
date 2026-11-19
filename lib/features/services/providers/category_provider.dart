import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/services/category_service.dart';
import 'package:service_pilot/features/services/services/firestore_category_service.dart';

/// Provides the active [ICategoryService] instance.
final categoryServiceProvider = Provider<ICategoryService>((ref) {
  return FirestoreCategoryService();
});

/// Holds the current search/filter query in the categories view.
final categoryQueryProvider = StateProvider<String>((ref) => '');

/// Fetches categories filtered by [categoryQueryProvider].
final categoriesListProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final service = ref.watch(categoryServiceProvider);
  final query = ref.watch(categoryQueryProvider);
  return service.searchCategories(query);
});

/// Holds the currently selected category for navigation to provider listing.
final selectedCategoryProvider = StateProvider<CategoryModel?>((ref) => null);

/// Fetches a single category by its unique ID.
final categoryByIdProvider =
    FutureProvider.family<CategoryModel?, String>((ref, id) async {
  final service = ref.watch(categoryServiceProvider);
  return service.getCategoryById(id);
});
