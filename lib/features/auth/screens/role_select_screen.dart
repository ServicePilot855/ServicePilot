import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

class _RoleOption {
  const _RoleOption({
    required this.icon,
    required this.title,
    required this.desc,
    required this.continueLabel,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String desc;
  final String continueLabel;
  final String route;
}

/// Step 1 of sign-up: choose which kind of account to create.
class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  List<_RoleOption> _roles(AppLocalizations l10n) => [
        _RoleOption(
          icon: Icons.home_outlined,
          title: l10n.roleSelectHomeownerTitle,
          desc: l10n.roleSelectHomeownerDesc,
          continueLabel: l10n.roleSelectHomeownerContinue,
          route: '/register/customer',
        ),
        _RoleOption(
          icon: Icons.handyman_outlined,
          title: l10n.roleSelectProviderTitle,
          desc: l10n.roleSelectProviderDesc,
          continueLabel: l10n.roleSelectProviderContinue,
          route: '/register/technician',
        ),
        _RoleOption(
          icon: Icons.apartment_rounded,
          title: l10n.roleSelectCompanyTitle,
          desc: l10n.roleSelectCompanyDesc,
          continueLabel: l10n.roleSelectCompanyContinue,
          route: '/register/company',
        ),
      ];

  int _selected = 0;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roles = _roles(l10n);
    final role = roles[_selected];

    return SpFlowPage(
      onBack: _back,
      step: 1,
      totalSteps: 3,
      bottom: SpPrimaryButton(
        label: role.continueLabel,
        onPressed: () => context.push(role.route),
      ),
      children: [
        SpPageHeader(
          title: l10n.roleSelectTitle,
          subtitle: l10n.roleSelectSubtitle,
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < roles.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          SpChoiceRow(
            icon: roles[i].icon,
            title: roles[i].title,
            description: roles[i].desc,
            selected: i == _selected,
            onTap: () => setState(() => _selected = i),
          ),
        ],
        const SizedBox(height: 20),
        Center(
          child: SpFooterLink(
            prompt: l10n.commonAlreadyHaveAccount,
            action: l10n.commonLogInLink,
            onTap: () => context.go('/login'),
          ),
        ),
      ],
    );
  }
}
