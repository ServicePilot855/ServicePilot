import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/services/firestore_provider_service.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';

/// Provides the active [IProviderService] instance.
final providerServiceProvider = Provider<IProviderService>((ref) {
  return FirestoreProviderService();
});

/// Resolves the provider document ID for the authenticated user based on role & email.
final currentProviderIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return '';
  final email = user.email.toLowerCase().trim();
  if (email == 'technician@test.com') return 'prov-virak-ac';
  if (email == 'company@test.com') return 'prov-fixco-company';
  if (email.contains('sophea.plumb')) return 'prov-dara-plumbing';
  return user.id;
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
