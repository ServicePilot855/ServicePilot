import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/services/firestore_provider_service.dart';
import 'package:service_pilot/features/providers/services/provider_contact_links.dart';

final companyProfileServiceProvider = Provider<CompanyProfileService>(
  (_) => CompanyProfileService(firestore: FirebaseFirestore.instance),
);

final editableCompanyProfileProvider =
    FutureProvider.autoDispose.family<ProviderModel?, UserModel>((ref, actor) {
  return ref.watch(companyProfileServiceProvider).load(actor);
});

class CompanyProfileService {
  const CompanyProfileService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static bool isValidContactLink(String value, String host) =>
      isValidProviderContactLink(value, host);

  DocumentReference<Map<String, dynamic>> _ownedProfile(
    UserModel actor,
    String providerId,
  ) {
    if (!actor.isCompany ||
        actor.isSuspended ||
        actor.id != providerId ||
        (actor.companyId != null && actor.companyId != providerId)) {
      throw StateError('Only the company administrator can edit this profile.');
    }
    return _firestore
        .collection(FirestoreProviderService.collectionName)
        .doc(providerId);
  }

  ProviderModel? _editableProfile(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return null;
    final profile = ProviderModel.fromFirestore(doc);
    return profile.isCompany &&
            const ['active', 'pending_verification', 'inactive']
                .contains(profile.status)
        ? profile
        : null;
  }

  Future<ProviderModel?> load(UserModel actor) async {
    final doc = await _ownedProfile(actor, actor.id).get();
    return _editableProfile(doc);
  }

  Future<void> save({
    required UserModel actor,
    required String providerId,
    required String businessName,
    required String description,
    required String serviceArea,
    required String telegramUrl,
    required String messengerUrl,
  }) async {
    final doc = _ownedProfile(actor, providerId);
    final name = businessName.trim();
    final about = description.trim();
    final area = serviceArea.trim();
    final telegram = telegramUrl.trim();
    final messenger = messengerUrl.trim();
    if (name.isEmpty ||
        name.length > 150 ||
        about.length > 2000 ||
        area.isEmpty ||
        area.length > 300 ||
        !isValidContactLink(telegram, 't.me') ||
        !isValidContactLink(messenger, 'm.me')) {
      throw ArgumentError('Invalid company profile fields.');
    }

    await _firestore.runTransaction((transaction) async {
      final existing = _editableProfile(await transaction.get(doc));
      if (existing == null) throw StateError('Company profile unavailable.');
      transaction.update(doc, {
        'businessName': name,
        'description': about,
        'serviceArea': area,
        if (area != existing.formattedCoverageAreas) ...{
          'coverageAreas': FieldValue.delete(),
          'serviceAreas': FieldValue.delete(),
        },
        'telegramUrl': telegram.isEmpty ? FieldValue.delete() : telegram,
        'messengerUrl': messenger.isEmpty ? FieldValue.delete() : messenger,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
