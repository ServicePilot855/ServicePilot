import 'package:flutter/material.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';

class TechnicianHome extends StatelessWidget {
  const TechnicianHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonHome(
      roleIcon: Icons.build_rounded,
      greeting: 'Your job board and earnings dashboard are coming soon.',
      role: AppRole.independentProvider,
    );
  }
}
