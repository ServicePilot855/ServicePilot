import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/bookings/widgets/provider_booking_list.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/services/company_profile_service.dart';
import 'package:service_pilot/features/services/widgets/provider_offering_list.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';

class CompanyHome extends ConsumerWidget {
  const CompanyHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canEditProfile = user != null && user.isCompany && !user.isSuspended;
    final company = canEditProfile
        ? ref.watch(editableCompanyProfileProvider(user)).valueOrNull
        : null;

    final resolvedId = ref.watch(currentProviderIdProvider);
    final providerId = resolvedId.isNotEmpty
        ? resolvedId
        : (user?.id.isNotEmpty == true ? user!.id : 'prov-fixco-company');
    final providerName = company?.displayName ??
        user?.companyName ??
        (user?.fullName.isNotEmpty == true
            ? user!.fullName
            : 'Phnom Penh Fix Co.');

    return ComingSoonHome(
      roleIcon: Icons.business_rounded,
      greeting: context.l10n.homeCompanyGreeting,
      role: AppRole.company,
      companyName: company?.displayName,
      primaryAction: canEditProfile
          ? SpPrimaryButton(
              label: context.l10n.companyProfileEdit,
              wrapLabel: true,
              onPressed: () => context.push('/home/company/profile'),
            )
          : null,
      extraContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProviderBookingList(providerId: providerId),
          const SizedBox(height: 24),
          ProviderOfferingList(
            providerId: providerId,
            providerName: providerName,
          ),
        ],
      ),
    );
  }
}
