import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/services/widgets/provider_offering_list.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';

class TechnicianHome extends ConsumerWidget {
  const TechnicianHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider.notifier).currentUser;
    final resolvedId = ref.watch(currentProviderIdProvider);
    final providerId = resolvedId.isNotEmpty
        ? resolvedId
        : (user?.id.isNotEmpty == true ? user!.id : 'prov-virak-ac');
    final providerName =
        user?.fullName.isNotEmpty == true ? user!.fullName : 'Virak Chan';

    return ComingSoonHome(
      roleIcon: Icons.build_rounded,
      greeting: context.l10n.homeTechnicianGreeting,
      role: AppRole.independentProvider,
      extraContent: ProviderOfferingList(
        providerId: providerId,
        providerName: providerName,
      ),
    );
  }
}
