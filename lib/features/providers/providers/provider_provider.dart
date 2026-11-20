import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/services/firestore_provider_service.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';

/// Provides the active [IProviderService] instance.
final providerServiceProvider = Provider<IProviderService>((ref) {
  return FirestoreProviderService();
});

/// Fetches a single provider by ID for US-11 (SCRUM-54).
final providerDetailsProvider =
    FutureProvider.family.autoDispose<ProviderModel?, String>((ref, providerId) async {
  final service = ref.watch(providerServiceProvider);
  return service.getProviderById(providerId);
});

/// Fetches active providers for a specific category for US-10 (SCRUM-55).
final categoryProvidersProvider =
    FutureProvider.family.autoDispose<List<ProviderModel>, String>((ref, categoryId) async {
  final service = ref.watch(providerServiceProvider);
  return service.getProviders(categoryId: categoryId);
});

/// Alias matching plural naming convention
final providersByCategoryProvider = categoryProvidersProvider;

/// Holds the currently selected provider in memory.
final selectedProviderProvider = StateProvider<ProviderModel?>((ref) => null);
