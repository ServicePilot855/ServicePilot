import 'package:flutter/material.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';

class CompanyHome extends StatelessWidget {
  const CompanyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoonHome(
      roleIcon: Icons.business_rounded,
      greeting: context.l10n.homeCompanyGreeting,
      role: AppRole.company,
    );
  }
}
