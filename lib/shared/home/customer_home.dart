import 'package:flutter/material.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/shared/widgets/coming_soon_home.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonHome(
      roleIcon: Icons.home_repair_service_rounded,
      greeting: 'Your home repair booking dashboard is coming soon.',
      role: AppRole.homeowner,
    );
  }
}
