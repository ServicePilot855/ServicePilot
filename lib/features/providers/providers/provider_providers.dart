import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/services/firestore_provider_service.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';

/// Provides the active [IProviderService] instance.
final providerServiceProvider = Provider<IProviderService>((ref) {
  return FirestoreProviderService();
});

/// Fetches active service providers for the specified [categoryId].
///
/// Corresponds to US-10 (SCRUM-55).
final providersByCategoryProvider =
    FutureProvider.family<List<ProviderModel>, String>((ref, categoryId) async {
  final service = ref.watch(providerServiceProvider);
  return await service.getProvidersByCategory(categoryId);
});

/// Fetches detailed profile for a single provider by [providerId].
///
/// Corresponds to US-11 (SCRUM-54).
final providerDetailsProvider =
    FutureProvider.family<ProviderModel?, String>((ref, providerId) async {
  final service = ref.watch(providerServiceProvider);
  return await service.getProviderById(providerId);
});
