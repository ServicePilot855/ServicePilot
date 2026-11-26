import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';

/// Resolves the current authenticated user for Platform Admin operations.
///
/// Can be overridden in tests to verify admin vs. non-admin authorization.
final activeAdminActorProvider = Provider<UserModel?>((ref) {
  return ref.watch(currentUserProvider);
});

/// Fetches pending provider applications (`status == 'pending_verification'`)
/// for the authorized Platform Admin (ADM-1 / ADM-2).
final pendingProvidersProvider =
    FutureProvider.autoDispose<List<ProviderModel>>((ref) async {
      final service = ref.watch(providerServiceProvider);
      final actor = ref.watch(activeAdminActorProvider);
      return service.getPendingProviders(actor: actor);
    });

/// Fetches approved and active providers (`status == 'active'`, `isVerified == true`).
final approvedProvidersProvider =
    FutureProvider.autoDispose<List<ProviderModel>>((ref) async {
      final service = ref.watch(providerServiceProvider);
      return service.getProviders(activeOnly: true);
    });
