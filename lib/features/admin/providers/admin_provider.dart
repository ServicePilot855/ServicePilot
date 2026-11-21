import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/features/admin/services/admin_provider_service.dart';
import 'package:service_pilot/features/admin/services/firestore_admin_provider_service.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';

/// Provides the active [IAdminProviderService] instance.
final adminProviderServiceProvider = Provider<IAdminProviderService>((ref) {
  return FirestoreAdminProviderService();
});

/// Reactive stream of all pending provider applications awaiting verification.
final pendingProvidersStreamProvider =
    StreamProvider.autoDispose<List<ProviderModel>>((ref) {
  final service = ref.watch(adminProviderServiceProvider);
  return service.watchPendingProviders();
});

/// Convenient count of applications currently in `pending_verification` state.
final pendingProvidersCountProvider = Provider.autoDispose<int>((ref) {
  final asyncState = ref.watch(pendingProvidersStreamProvider);
  return asyncState.maybeWhen(
    data: (list) => list.length,
    orElse: () => 0,
  );
});
