import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';

/// Cloud Firestore implementation of [IOfferingService].
///
/// Features:
/// - Reads live offerings from `/offerings` with category and provider filtering.
/// - Enforces data validation: offerings with [OfferingPricingMode.quoteRequired]
///   strip fixed checkout pricing to prevent cart integration.
/// - Resilient fallback: returns [OfferingService.defaultOfferings] if Firestore is offline or empty.
class FirestoreOfferingService implements IOfferingService {
  final FirebaseFirestore? _injectedFirestore;
  final OfferingService _fallbackService;

  FirestoreOfferingService({
    FirebaseFirestore? firestore,
    List<OfferingModel>? fallbackOfferings,
  })  : _injectedFirestore = firestore,
        _fallbackService = OfferingService(initialOfferings: fallbackOfferings);

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  bool get _hasFirestore =>
      _injectedFirestore != null || Firebase.apps.isNotEmpty;

  static const String collectionName = 'offerings';

  @override
  Future<List<OfferingModel>> getOfferings({
    String? categoryId,
    String? providerId,
    bool activeOnly = true,
  }) async {
    if (_hasFirestore) {
      try {
        Query query = _firestore.collection(collectionName);
        if (activeOnly) {
          query = query.where('isActive', isEqualTo: true);
        }
        if (categoryId != null && categoryId.isNotEmpty) {
          query = query.where('categoryId', isEqualTo: categoryId);
        }
        if (providerId != null && providerId.isNotEmpty) {
          query = query.where('providerId', isEqualTo: providerId);
        }

        final snapshot = await query.get();
        // Return live Firestore results. When filtering for a specific provider,
        // if they have 0 offerings, return an empty list rather than leaking
        // another provider's demo seed offerings.
        if (snapshot.docs.isNotEmpty ||
            (providerId != null && providerId.isNotEmpty)) {
          return snapshot.docs
              .map((doc) => OfferingModel.fromFirestore(doc))
              .toList();
        }
      } catch (e) {
        debugPrint(
          '[FirestoreOfferingService] Get offerings error ($e); falling back to memory seed.',
        );
      }
    }

    return _fallbackService.getOfferings(
      categoryId: categoryId,
      providerId: providerId,
      activeOnly: activeOnly,
    );
  }

  @override
  Future<OfferingModel?> getOfferingById(String id) async {
    if (_hasFirestore) {
      try {
        final doc = await _firestore.collection(collectionName).doc(id).get();
        if (doc.exists) {
          return OfferingModel.fromFirestore(doc);
        }
        // If document definitely does not exist in Firestore, return null
        return null;
      } catch (e) {
        debugPrint(
          '[FirestoreOfferingService] Get offering error ($e); falling back to memory seed.',
        );
      }
    }
    return _fallbackService.getOfferingById(id);
  }

  @override
  Future<OfferingModel> createOffering(OfferingModel offering) async {
    // Sanitize: quote required offerings must never hold a fixed checkout price
    final sanitized =
        offering.isQuoteRequired ? offering.copyWith(price: null) : offering;

    if (offering.isFixedPrice) {
      if (!OfferingModel.isValidFixedPrice(offering.price)) {
        throw ArgumentError.value(
            offering.price, 'price', 'Invalid fixed price');
      }
      if (!_hasFirestore) throw StateError('Firestore unavailable');
    }

    if (_hasFirestore) {
      try {
        final docRef = !sanitized.isFixedPrice && sanitized.id.isNotEmpty
            ? _firestore.collection(collectionName).doc(sanitized.id)
            : _firestore.collection(collectionName).doc();

        final finalOffering = sanitized.copyWith(
          id: docRef.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await docRef.set(finalOffering.toMap());
        try {
          await _fallbackService.createOffering(finalOffering);
        } catch (error) {
          debugPrint(
              '[FirestoreOfferingService] Could not cache offering: $error');
        }
        return finalOffering;
      } catch (e) {
        if (offering.isFixedPrice) rethrow;
        debugPrint(
          '[FirestoreOfferingService] Create offering Firestore error ($e); saving to fallback store.',
        );
      }
    }

    return _fallbackService.createOffering(sanitized);
  }

  @override
  Future<OfferingModel> updateOffering(OfferingModel offering) async {
    if (offering.isFixedPrice &&
        !OfferingModel.isValidFixedPrice(offering.price)) {
      throw ArgumentError.value(offering.price, 'price', 'Invalid fixed price');
    }
    if (!_hasFirestore) throw StateError('Firestore unavailable');

    final updatedAt = DateTime.now();
    final changes = {
      ...offering.editableFields,
      'updatedAt': updatedAt.toIso8601String(),
    };
    await _firestore
        .collection(collectionName)
        .doc(offering.id)
        .update(changes);
    final saved = OfferingModel.fromMap({...offering.toMap(), ...changes});
    if (await _fallbackService.getOfferingById(saved.id) != null) {
      await _fallbackService.updateOffering(saved);
    }
    return saved;
  }

  @override
  Future<void> deleteOffering(String id) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        await _firestore.collection(collectionName).doc(id).delete();
      } catch (e) {
        debugPrint('[FirestoreOfferingService] Delete offering error ($e)');
      }
    }
    // Best-effort in-memory fallback cache delete
    try {
      await _fallbackService.deleteOffering(id);
    } catch (e) {
      debugPrint(
          '[FirestoreOfferingService] Fallback cache delete error (ignored): $e');
    }
  }
}
