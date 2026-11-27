import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/services/firestore_offering_service.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';

/// Provides the active [IOfferingService] instance.
final offeringServiceProvider = Provider<IOfferingService>((ref) {
  return FirestoreOfferingService();
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
