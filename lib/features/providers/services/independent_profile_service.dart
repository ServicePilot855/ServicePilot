import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/services/firestore_provider_service.dart';
import 'package:service_pilot/features/providers/services/provider_contact_links.dart';

final independentProfileServiceProvider = Provider<IndependentProfileService>(
  (_) => IndependentProfileService(
    firestore: Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null,
  ),
);

final editableIndependentProfileProvider =
    FutureProvider.autoDispose.family<ProviderModel?, UserModel>((ref, actor) {
  return ref.watch(independentProfileServiceProvider).load(actor);
});

class IndependentProfileService {
  const IndependentProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static bool isValidContactLink(String value, String host) =>
      isValidProviderContactLink(value, host);

  DocumentReference<Map<String, dynamic>>? _ownedProfile(
    UserModel actor,
    String providerId,
  ) {
    if (!actor.isIndependentTechnician ||
        actor.isSuspended ||
        actor.id != providerId) {
      throw StateError(
          'Only the independent technician can edit this profile.');
    }
    return _firestore
        ?.collection(FirestoreProviderService.collectionName)
        .doc(providerId);
  }

  ProviderModel? _editableProfile(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return null;
    final profile = ProviderModel.fromFirestore(doc);
    return profile.isIndependent && profile.status.toLowerCase() != 'suspended'
        ? profile
        : null;
  }

  ProviderModel _standaloneProfile(UserModel actor) => ProviderModel(
        id: actor.id,
        name: actor.fullName,
        type: ProviderType.independent,
        serviceArea: actor.serviceArea ?? '',
        email: actor.email,
        phone: actor.phoneNumber,
        status: actor.status,
        isVerified: actor.status == 'active',
      );

  Future<ProviderModel?> load(UserModel actor) async {
    final docRef = _ownedProfile(actor, actor.id);
    if (docRef == null) return null;
    final doc = await docRef.get();
    if (!doc.exists) return _standaloneProfile(actor);
    return _editableProfile(doc);
  }

  Future<void> save({
    required UserModel actor,
    required String providerId,
    required String fullName,
    required String description,
    required String serviceArea,
    required String telegramUrl,
    required String messengerUrl,
  }) async {
    final doc = _ownedProfile(actor, providerId);
    final name = fullName.trim();
    final about = description.trim();
    final area = serviceArea.trim();
    final telegram = telegramUrl.trim();
    final messenger = messengerUrl.trim();

    if (name.isEmpty ||
        name.length > 100 ||
        about.length > 2000 ||
        area.isEmpty ||
        area.length > 300 ||
        !isValidContactLink(telegram, 't.me') ||
        !isValidContactLink(messenger, 'm.me')) {
      throw ArgumentError('Invalid technician profile fields.');
    }

    final firestore = _firestore;
    if (firestore == null || doc == null) {
      throw StateError('Technician profile service unavailable.');
    }

    await firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(doc);
      final userDoc = firestore.collection('users').doc(actor.id);
      final userSnapshot = await transaction.get(userDoc);

      if (!docSnapshot.exists) {
        transaction.set(doc, {
          'id': actor.id,
          'name': name,
          'fullName': name,
          if (actor.email.trim().isNotEmpty) 'email': actor.email.trim(),
          'phoneNumber': actor.phoneNumber,
          'providerType': 'independent',
          'status': 'pending_verification',
          'isVerified': false,
          'description': about,
          'bio': about,
          'serviceArea': area,
          if (telegram.isNotEmpty) 'telegramUrl': telegram,
          if (messenger.isNotEmpty) 'messengerUrl': messenger,
          'createdAt': Timestamp.fromDate(actor.createdAt ?? DateTime.now()),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final existing = _editableProfile(docSnapshot);
        if (existing == null) {
          throw StateError('Technician profile unavailable.');
        }

        transaction.update(doc, {
          'name': name,
          'fullName': name,
          'description': about,
          'bio': about,
          'serviceArea': area,
          if (area != existing.formattedCoverageAreas) ...{
            'coverageAreas': FieldValue.delete(),
            'serviceAreas': FieldValue.delete(),
          },
          'telegramUrl': telegram.isEmpty ? FieldValue.delete() : telegram,
          'messengerUrl': messenger.isEmpty ? FieldValue.delete() : messenger,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (userSnapshot.exists) {
        transaction.update(userDoc, {
          'fullName': name,
          'serviceArea': area,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
