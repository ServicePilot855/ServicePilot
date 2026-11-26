import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/bookings/screens/incoming_booking_screen.dart';
import 'package:service_pilot/features/bookings/widgets/provider_booking_list.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/services/independent_profile_service.dart';
import 'package:service_pilot/features/services/widgets/provider_offering_list.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';

class TechnicianHome extends ConsumerWidget {
  const TechnicianHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canEditProfile =
        user != null && user.isIndependentTechnician && !user.isSuspended;
    final technician = canEditProfile
        ? ref.watch(editableIndependentProfileProvider(user)).valueOrNull
        : null;

    final resolvedId = ref.watch(currentProviderIdProvider);
    final providerId = resolvedId.isNotEmpty
        ? resolvedId
        : (user?.id.isNotEmpty == true ? user!.id : 'prov-virak-ac');
    final providerName = technician?.displayName ??
        (user?.fullName.isNotEmpty == true ? user!.fullName : 'Virak Chan');

    return ComingSoonHome(
      roleIcon: Icons.build_rounded,
      greeting: context.l10n.homeTechnicianGreeting,
      role: AppRole.independentProvider,
      displayName: technician?.displayName,
      primaryAction: canEditProfile
          ? SpPrimaryButton(
              label: context.l10n.technicianProfileEdit,
              wrapLabel: true,
              onPressed: () => context.push('/home/technician/profile'),
            )
          : null,
      secondaryAction: user?.canViewBookingInbox == true
          ? SpSecondaryButton(
              label: context.l10n.bookingInboxTitle,
              icon: Icons.inbox_outlined,
              wrapLabel: true,
              onPressed: () => context.push(IncomingBookingScreen.path),
            )
          : null,
      extraContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null && user.canViewBookingInbox) ...[
            ProviderBookingList(providerId: user.id),
            const SizedBox(height: 24),
          ],
          ProviderOfferingList(
            providerId: providerId,
            providerName: providerName,
          ),
        ],
      ),
    );
  }
}
