import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/bookings/widgets/technician_job_list.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';

/// Company technician home: the jobs assigned to the signed-in technician
/// (TECHJOB-1 / SCRUM-100).
class CompanyTechnicianHome extends ConsumerWidget {
  const CompanyTechnicianHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canViewJobs =
        ref.watch(currentUserProvider)?.canViewAssignedJobs ?? false;

    return ComingSoonHome(
      roleIcon: Icons.engineering_rounded,
      greeting: context.l10n.homeCompanyTechnicianGreeting,
      role: AppRole.companyTechnician,
      showComingSoonNotice: !canViewJobs,
      extraContent: canViewJobs ? const TechnicianJobList() : null,
    );
  }
}
