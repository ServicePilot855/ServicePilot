import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_brand.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Placeholder home shown to every role until its features are built:
/// confirms who is signed in, says what comes next, and offers log out.
class ComingSoonHome extends ConsumerWidget {
  const ComingSoonHome({
    super.key,
    required this.roleIcon,
    required this.greeting,
    required this.role,
  });

  final IconData roleIcon;
  final String greeting;
  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.watch(authProvider.notifier).currentUser;
    final name = user?.fullName ?? l10n.homeFallbackName;
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    final companyName = user?.companyName;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SpContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SpLogoMark(size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusChip),
                          ),
                          child: Text(
                            role.label(context.l10n),
                            style: AppTheme.text(
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.homeGreeting(firstName),
                    style: AppTheme.display(size: 30),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  companyName == null
                      ? name
                      : l10n.homeNameWithCompany(name, companyName),
                  style: AppTheme.text(
                    size: 15,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(roleIcon, size: 28, color: AppTheme.primary),
                      const SizedBox(height: 12),
                      Text(l10n.homeSignedIn,
                          style: AppTheme.display(size: 22)),
                      const SizedBox(height: 6),
                      Text(
                        greeting,
                        style: AppTheme.text(
                          size: 15,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SpNotice(
                        icon: Icons.hourglass_top_rounded,
                        tone: SpTone.waiting,
                        message: l10n.homeComingSoonNotice,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SpSecondaryButton(
                  label: l10n.homeLogOut,
                  icon: Icons.logout_rounded,
                  foregroundColor: AppTheme.errorDeep,
                  onPressed: () {
                    authNotifier.logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
