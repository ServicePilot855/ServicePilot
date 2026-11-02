import 'package:flutter/material.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';

class CompanyTechnicianHome extends StatelessWidget {
  const CompanyTechnicianHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonHome(
      roleIcon: Icons.engineering_rounded,
      greeting: 'Your assigned jobs and schedule are coming soon.',
      role: AppRole.companyTechnician,
    );
  }
}
