import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';

/// Production-ready Cloud Firestore implementation of [IProviderService].
///
/// Features:
/// - Connects to the cloud `providers` collection with role and category filters.
/// - Enforces US-10 (SCRUM-55) & ADM-2 (SCRUM-94) AC: only retrieves `status == 'active'`
///   and verified providers for customer discovery.
/// - Supports Platform Admin review and approval of `pending_verification` providers
///   (`getPendingProviders` and `approveProvider`).
/// - Seamless resilient development fallback: if the Firestore database has not yet been
///   created in the Firebase Console or the device is offline, it serves realistic Phnom Penh
///   demo providers to ensure uninterrupted development and testing.
class FirestoreProviderService implements IProviderService {
  final FirebaseFirestore? _injectedFirestore;
  final List<ProviderModel> _localProviders;

  static final List<ProviderModel> _sharedLocalProviders =
      List<ProviderModel>.from(ProviderService.defaultProviders);
  static final _localChanges = StreamController<void>.broadcast();

  FirestoreProviderService({
    FirebaseFirestore? firestore,
    List<ProviderModel>? initialProviders,
  })  : _injectedFirestore = firestore,
        _localProviders = initialProviders != null
            ? List<ProviderModel>.from(initialProviders)
            : _sharedLocalProviders;

  bool get _hasFirestore =>
      _injectedFirestore != null || Firebase.apps.isNotEmpty;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'providers';

  /// Pre-seeded verified and pending providers covering Phnom Penh service areas.
  static final List<ProviderModel> seedProviders =
      ProviderService.defaultProviders;

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

    return _localProviders.where((p) {
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

      return matchName || matchDesc || matchBio || matchSpecialty || matchArea;
    }).toList();
  }

  @override
  Future<List<ProviderModel>> getProvidersByCategory(String categoryId) async {
    // 1. If Firebase is initialized, attempt real Firestore fetch
    if (_hasFirestore) {
      try {
        final byId = <String, ProviderModel>{};

        final querySnapshot = await _firestore
            .collection(collectionName)
            .where('status', isEqualTo: 'active')
            .where('categoryIds', arrayContains: categoryId)
            .get();

        for (final doc in querySnapshot.docs) {
          final p = ProviderModel.fromFirestore(doc);
          if (p.isApprovedAndActive) byId[p.id] = p;
        }

        // Also include active providers who published an active offering in this category
        // even if their provider document's categoryIds array hasn't been synced yet.
        try {
          final offeringSnap = await _firestore
              .collection('offerings')
              .where('isActive', isEqualTo: true)
              .where('categoryId', isEqualTo: categoryId)
              .get();
          final extraProviderIds = offeringSnap.docs
              .map((d) => d.data()['providerId'] as String? ?? '')
              .where((id) => id.isNotEmpty && !byId.containsKey(id))
              .toSet();
          for (final pid in extraProviderIds) {
            final pDoc =
                await _firestore.collection(collectionName).doc(pid).get();
            if (pDoc.exists) {
              final p = ProviderModel.fromFirestore(pDoc);
              if (p.isApprovedAndActive) byId[p.id] = p;
            }
          }
        } catch (e) {
          debugPrint(
              '[FirestoreProviderService] Offerings category lookup warning: $e');
        }

        if (byId.isNotEmpty) {
          return byId.values.toList();
        }
      } catch (e) {
        debugPrint(
            '[FirestoreProviderService] Firestore fetch exception ($e); falling back to seed providers.');
      }
    }

    // 2. Resilient Fallback: Filter seed providers by status == 'active' and categoryId
    return List.unmodifiable(
      _localProviders.where(
        (p) => p.isApprovedAndActive && p.categoryIds.contains(categoryId),
      ),
    );
  }

  @override
  Future<ProviderModel?> getProviderById(String providerId) async {
    if (_injectedFirestore != null || Firebase.apps.isNotEmpty) {
      try {
        final doc =
            await _firestore.collection(collectionName).doc(providerId).get();
        if (doc.exists) {
          return ProviderModel.fromFirestore(doc);
        }
      } catch (e) {
        debugPrint(
          '[FirestoreProviderService] Get provider by ID exception ($e); checking seed providers.',
        );
      }
    }

    try {
      return _localProviders.firstWhere((p) => p.id == providerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ProviderModel>> getPendingProviders({
    required UserModel? actor,
  }) async {
    if (actor == null || !actor.isAdmin) {
      throw UnauthorizedProviderApprovalException(
        userId: actor?.id,
        role: actor?.role.value,
      );
    }

    if (_hasFirestore) {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('status', isEqualTo: 'pending_verification')
          .get();
      return snapshot.docs
          .map((doc) => ProviderModel.fromFirestore(doc))
          .toList();
    }

    return List.unmodifiable(
      _localProviders.where((p) => p.isPendingVerification),
    );
  }

  @override
  Stream<List<ProviderModel>> watchPendingProviders({
    required UserModel? actor,
  }) async* {
    if (actor == null || !actor.isAdmin) {
      throw UnauthorizedProviderApprovalException(
        userId: actor?.id,
        role: actor?.role.value,
      );
    }

    if (_hasFirestore) {
      yield* _firestore
          .collection(collectionName)
          .where('status', isEqualTo: 'pending_verification')
          .snapshots()
          .map(
            (snapshot) => List.unmodifiable(
              snapshot.docs.map((doc) => ProviderModel.fromFirestore(doc)),
            ),
          );
      return;
    }

    yield List.unmodifiable(
      _localProviders.where((p) => p.isPendingVerification),
    );
    await for (final _ in _localChanges.stream) {
      yield List.unmodifiable(
        _localProviders.where((p) => p.isPendingVerification),
      );
    }
  }

  @override
  Stream<List<ProviderModel>> watchActiveProviders() async* {
    if (_hasFirestore) {
      yield* _firestore
          .collection(collectionName)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map(
            (snapshot) => List.unmodifiable(
              snapshot.docs
                  .map((doc) => ProviderModel.fromFirestore(doc))
                  .where((p) => p.isApprovedAndActive),
            ),
          );
      return;
    }

    yield List.unmodifiable(
      _localProviders.where((p) => p.isApprovedAndActive),
    );
    await for (final _ in _localChanges.stream) {
      yield List.unmodifiable(
        _localProviders.where((p) => p.isApprovedAndActive),
      );
    }
  }

  @override
  Future<ProviderModel> approveProvider({
    required String providerId,
    required UserModel? actor,
  }) async {
    if (actor == null || !actor.isAdmin) {
      throw UnauthorizedProviderApprovalException(
        providerId: providerId,
        userId: actor?.id,
        role: actor?.role.value,
      );
    }

    final existing = await getProviderById(providerId);
    if (existing == null) {
      throw ProviderNotFoundException(providerId);
    }

    if (!existing.isPendingVerification) {
      throw InvalidProviderApprovalStateException(
        providerId: providerId,
        currentStatus: existing.status,
      );
    }

    final now = DateTime.now();
    final approved = existing.copyWith(
      status: 'active',
      isVerified: true,
      updatedAt: now,
    );

    if (_hasFirestore) {
      final providerRef = _firestore.collection(collectionName).doc(providerId);
      final providerSnap = await providerRef.get();
      if (providerSnap.exists) {
        await providerRef.update({
          'status': 'active',
          'isVerified': true,
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        await providerRef.set({
          'id': approved.id,
          'name': approved.name,
          if (approved.businessName != null)
            'businessName': approved.businessName,
          if (approved.email.trim().isNotEmpty) 'email': approved.email.trim(),
          if (approved.phone.trim().isNotEmpty)
            'phoneNumber': approved.phone.trim(),
          'providerType': approved.type.value,
          'status': 'active',
          'isVerified': true,
          'serviceArea': approved.serviceArea,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      final userRef = _firestore.collection('users').doc(providerId);
      final userSnap = await userRef.get();
      if (userSnap.exists) {
        await userRef.update({
          'status': 'active',
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    }

    final localIndex = _localProviders.indexWhere((p) => p.id == providerId);
    if (localIndex != -1) {
      _localProviders[localIndex] = approved;
    } else {
      _localProviders.add(approved);
    }
    _localChanges.add(null);

    return approved;
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
