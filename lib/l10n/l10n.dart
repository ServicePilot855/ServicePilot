import 'package:flutter/widgets.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

export 'package:service_pilot/l10n/app_localizations.dart';

/// Locales the app offers today.
///
/// Khmer strings live in `app_km.arb`. While that file is incomplete the app
/// stays English-only; add `Locale('km')` here once it is translated (any key
/// missing from it falls back to English).
const List<Locale> appSupportedLocales = [Locale('en')];

extension L10nContext on BuildContext {
  /// The app's strings for the current locale.
  ///
  /// Falls back to English when no localisation delegate is installed, so a
  /// screen pumped on its own in a widget test still renders.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('en'));
}

extension AppRoleL10n on AppRole {
  /// The role's name in the user's language. Use this in the interface;
  /// [AppRoleExtension.displayName] stays English for logs and tests.
  String label(AppLocalizations l10n) {
    switch (this) {
      case AppRole.homeowner:
        return l10n.roleHomeowner;
      case AppRole.independentProvider:
        return l10n.roleIndependentProvider;
      case AppRole.company:
        return l10n.roleCompany;
      case AppRole.companyTechnician:
        return l10n.roleCompanyTechnician;
      case AppRole.admin:
        return l10n.roleAdmin;
    }
  }
}
