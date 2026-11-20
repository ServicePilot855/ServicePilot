import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';

/// Production-ready Cloud Firestore implementation of [IProviderService].
///
/// Features:
/// - Connects to the cloud `providers` collection with role and category filters.
/// - Enforces US-10 (SCRUM-55) AC: only retrieves `status == 'active'` providers.
/// - Seamless resilient development fallback: if the Firestore database has not yet been
///   created in the Firebase Console or the device is offline, it serves realistic Phnom Penh
///   demo providers to ensure uninterrupted development and testing.
class FirestoreProviderService implements IProviderService {
  final FirebaseFirestore? _injectedFirestore;

  FirestoreProviderService({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'providers';

  /// Pre-seeded verified providers covering Phnom Penh service areas and all categories.
  static final List<ProviderModel> seedProviders = ProviderService.defaultProviders;

  @override
  Future<List<ProviderModel>> getProviders({
    String? categoryId,
    bool activeOnly = true,
  }) async {
    if (categoryId != null) {
      final list = await getProvidersByCategory(categoryId);
      if (activeOnly) {
        return list.where((p) => p.isApprovedAndActive).toList();
      }
      return list;
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        Query<Map<String, dynamic>> query =
            _firestore.collection(collectionName);
        if (activeOnly) {
          query = query.where('status', isEqualTo: 'active');
        }
        final snapshot = await query.get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs
              .map((doc) => ProviderModel.fromFirestore(doc))
              .toList();
        }
      } catch (e) {
        debugPrint('[FirestoreProviderService] getProviders error: $e');
      }
    }

    return seedProviders.where((p) {
      if (activeOnly && !p.isApprovedAndActive) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<ProviderModel>> searchProviders(
    String query, {
    String? categoryId,
  }) async {
    final clean = query.trim().toLowerCase();
    final base = await getProviders(categoryId: categoryId);
    if (clean.isEmpty) return base;

    return base.where((p) {
      final matchName = p.name.toLowerCase().contains(clean);
      final matchDesc = p.description.toLowerCase().contains(clean);
      final matchBio = p.bio.toLowerCase().contains(clean);
      final matchSpecialty =
          p.specialties.any((s) => s.toLowerCase().contains(clean));
      final matchArea =
          p.coverageAreas.any((a) => a.toLowerCase().contains(clean)) ||
          p.serviceArea.toLowerCase().contains(clean);

      return matchName ||
          matchDesc ||
          matchBio ||
          matchSpecialty ||
          matchArea;
    }).toList();
  }

  @override
  Future<List<ProviderModel>> getProvidersByCategory(String categoryId) async {
    // 1. If Firebase is initialized, attempt real Firestore fetch
    if (Firebase.apps.isNotEmpty) {
      try {
        final querySnapshot = await _firestore
            .collection(collectionName)
            .where('status', isEqualTo: 'active')
            .where('categoryIds', arrayContains: categoryId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs
              .map((doc) => ProviderModel.fromFirestore(doc))
              .toList();
        }
      } catch (e) {
        debugPrint(
            '[FirestoreProviderService] Firestore fetch exception ($e); falling back to seed providers.');
      }
    }

    // 2. Resilient Fallback: Filter seed providers by status == 'active' and categoryId
    return List.unmodifiable(
      seedProviders.where((p) =>
          p.isApprovedAndActive && p.categoryIds.contains(categoryId)),
    );
  }

  @override
  Future<ProviderModel?> getProviderById(String providerId) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final doc =
            await _firestore.collection(collectionName).doc(providerId).get();
        if (doc.exists) {
          return ProviderModel.fromFirestore(doc);
        }
      } catch (e) {
        debugPrint(
            '[FirestoreProviderService] Get provider by ID exception ($e); checking seed providers.');
      }
    }

    try {
      return seedProviders.firstWhere((p) => p.id == providerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> seedInitialProviders() async {
    if (Firebase.apps.isEmpty) return;

    try {
      final batch = _firestore.batch();
      for (final provider in seedProviders) {
        final docRef = _firestore.collection(collectionName).doc(provider.id);
        batch.set(docRef, provider.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint(
          '[FirestoreProviderService] Successfully seeded ${seedProviders.length} providers to Firestore.');
    } catch (e) {
      debugPrint('[FirestoreProviderService] Error seeding providers: $e');
    }
  }
}
