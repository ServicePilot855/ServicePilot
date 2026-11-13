import 'package:flutter/material.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoonHome(
      roleIcon: Icons.admin_panel_settings_rounded,
      greeting: context.l10n.homeAdminGreeting,
      role: AppRole.admin,
    );
  }
}
