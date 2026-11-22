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

  static const String collectionName = 'offerings';

  @override
  Future<List<OfferingModel>> getOfferings({
    String? categoryId,
    String? providerId,
    bool activeOnly = true,
  }) async {
    if (Firebase.apps.isNotEmpty) {
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
        if (snapshot.docs.isNotEmpty) {
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
    if (Firebase.apps.isNotEmpty) {
      try {
        final doc = await _firestore.collection(collectionName).doc(id).get();
        if (doc.exists) {
          return OfferingModel.fromFirestore(doc);
        }
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
    final sanitized = offering.isQuoteRequired
        ? offering.copyWith(price: null)
        : offering;

    if (Firebase.apps.isNotEmpty) {
      try {
        final docRef = sanitized.id.isNotEmpty
            ? _firestore.collection(collectionName).doc(sanitized.id)
            : _firestore.collection(collectionName).doc();

        final finalOffering = sanitized.copyWith(
          id: docRef.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await docRef.set(finalOffering.toMap());
        await _fallbackService.createOffering(finalOffering);
        return finalOffering;
      } catch (e) {
        debugPrint(
          '[FirestoreOfferingService] Create offering Firestore error ($e); saving to fallback store.',
        );
      }
    }

    return _fallbackService.createOffering(sanitized);
  }

  @override
  Future<OfferingModel> updateOffering(OfferingModel offering) async {
    final sanitized = offering.isQuoteRequired
        ? offering.copyWith(price: null)
        : offering;

    if (Firebase.apps.isNotEmpty) {
      try {
        final finalOffering = sanitized.copyWith(updatedAt: DateTime.now());
        await _firestore
            .collection(collectionName)
            .doc(finalOffering.id)
            .update(finalOffering.toMap());

        await _fallbackService.updateOffering(finalOffering);
        return finalOffering;
      } catch (e) {
        debugPrint(
          '[FirestoreOfferingService] Update offering Firestore error ($e); saving to fallback store.',
        );
      }
    }

    return _fallbackService.updateOffering(sanitized);
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
    await _fallbackService.deleteOffering(id);
  }
}
