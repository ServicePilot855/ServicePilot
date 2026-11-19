import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/services/category_service.dart';

/// Production Cloud Firestore implementation of [ICategoryService].
///
/// Features:
/// - Fetches live service categories from Firestore `/categories`.
/// - Supports searching categories across titles, descriptions, and popular service tags.
/// - Resilient development fallback: seamlessly returns [CategoryService.defaultCategories]
///   if the cloud database is empty or offline, preventing application crashes.
/// - Provides [seedInitialCategories] to batch-seed categories to Firestore.
class FirestoreCategoryService implements ICategoryService {
  final FirebaseFirestore? _injectedFirestore;

  FirestoreCategoryService({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'categories';

  @override
  Future<List<CategoryModel>> getCategories() async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final querySnapshot = await _firestore
            .collection(collectionName)
            .where('isActive', isEqualTo: true)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList();
        }
      } catch (e) {
        debugPrint(
            '[FirestoreCategoryService] Firestore categories fetch error ($e); falling back to default categories.');
      }
    }

    // Resilient fallback to default Phnom Penh categories
    return List.unmodifiable(
      CategoryService.defaultCategories.where((cat) => cat.isActive),
    );
  }

  @override
  Future<CategoryModel?> getCategoryById(String id) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final doc =
            await _firestore.collection(collectionName).doc(id).get();
        if (doc.exists) {
          return CategoryModel.fromFirestore(doc);
        }
      } catch (e) {
        debugPrint(
            '[FirestoreCategoryService] Get category by ID error ($e); checking default categories.');
      }
    }

    try {
      return CategoryService.defaultCategories
          .firstWhere((cat) => cat.id == id && cat.isActive);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CategoryModel>> searchCategories(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    final allCategories = await getCategories();

    if (cleanQuery.isEmpty) {
      return allCategories;
    }

    return allCategories.where((cat) {
      final matchName = cat.name.toLowerCase().contains(cleanQuery);
      final matchDesc = cat.description.toLowerCase().contains(cleanQuery);
      final matchServices = cat.popularServices.any(
        (service) => service.toLowerCase().contains(cleanQuery),
      );
      return matchName || matchDesc || matchServices;
    }).toList();
  }

  @override
  Future<void> seedInitialCategories() async {
    if (Firebase.apps.isEmpty) return;

    try {
      final batch = _firestore.batch();
      for (final category in CategoryService.defaultCategories) {
        final docRef = _firestore.collection(collectionName).doc(category.id);
        batch.set(docRef, category.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint(
          '[FirestoreCategoryService] Successfully seeded ${CategoryService.defaultCategories.length} categories to Firestore.');
    } catch (e) {
      debugPrint('[FirestoreCategoryService] Error seeding categories: $e');
    }
  }
}
