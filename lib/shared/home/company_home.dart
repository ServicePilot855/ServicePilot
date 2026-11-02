import 'package:flutter/material.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';

class CompanyHome extends StatelessWidget {
  const CompanyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonHome(
      roleIcon: Icons.business_rounded,
      greeting: 'Your team management and booking overview are coming soon.',
      role: AppRole.company,
    );
  }
}
