import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/services/firestore_offering_service.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';

/// Provides the active [IOfferingService] instance.
final offeringServiceProvider = Provider<IOfferingService>((ref) {
  return FirestoreOfferingService();
});

final offeringEditorProviderId = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null ||
      user.isSuspended ||
      !(user.isCompany || user.isIndependentTechnician)) {
    return null;
  }
  final id = ref.watch(currentProviderIdProvider);
  if (id.isEmpty ||
      (user.isCompany && user.companyId != null && user.companyId != id)) {
    return null;
  }
  return id;
});

/// Fetches offerings for a specific provider.
final offeringsByProviderProvider =
    FutureProvider.family<List<OfferingModel>, String>((ref, providerId) async {
  final service = ref.watch(offeringServiceProvider);
  return service.getOfferings(providerId: providerId);
});

/// Fetches offerings under a specific service category.
final offeringsByCategoryProvider =
    FutureProvider.family<List<OfferingModel>, String>((ref, categoryId) async {
  final service = ref.watch(offeringServiceProvider);
  return service.getOfferings(categoryId: categoryId);
});

/// Fetches single offering details by ID.
final offeringDetailProvider =
    FutureProvider.family<OfferingModel?, String>((ref, offeringId) async {
  final service = ref.watch(offeringServiceProvider);
  return service.getOfferingById(offeringId);
});
