import 'package:flutter/material.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonHome(
      roleIcon: Icons.admin_panel_settings_rounded,
      greeting: 'The platform admin dashboard is coming soon.',
      role: AppRole.admin,
    );
  }
}
