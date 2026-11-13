import 'package:flutter/material.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';

class TechnicianHome extends StatelessWidget {
  const TechnicianHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoonHome(
      roleIcon: Icons.build_rounded,
      greeting: context.l10n.homeTechnicianGreeting,
      role: AppRole.independentProvider,
    );
  }
}
