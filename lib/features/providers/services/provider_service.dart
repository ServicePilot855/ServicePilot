import 'package:service_pilot/features/providers/models/provider_model.dart';

/// Contract for service provider data access.
///
/// Corresponds to US-10 (SCRUM-55) & US-11 (SCRUM-54).
abstract class IProviderService {
  /// Fetches approved and active service providers offering services in [categoryId].
  ///
  /// Only returns providers with `status == 'active'` (pending verification excluded per US-10 AC).
  Future<List<ProviderModel>> getProvidersByCategory(String categoryId);

  /// Fetches a single provider profile by their unique [providerId].
  Future<ProviderModel?> getProviderById(String providerId);

  /// Seeds initial demo providers into the database for rapid testing and bootstrapping.
  Future<void> seedInitialProviders();
}
