/// Defines the roles a user can have in the ServicePilot platform.
enum AppRole {
  homeowner,
  independentProvider,
  company,
  companyTechnician,
  admin,
}

extension AppRoleExtension on AppRole {
  /// Human-readable display name shown in the UI.
  String get displayName {
    switch (this) {
      case AppRole.homeowner:
        return 'Customer';
      case AppRole.independentProvider:
        return 'Independent Technician';
      case AppRole.company:
        return 'Service Company';
      case AppRole.companyTechnician:
        return 'Company Technician';
      case AppRole.admin:
        return 'Platform Admin';
    }
  }

  /// Backend-facing string value for the role.
  String get value {
    switch (this) {
      case AppRole.homeowner:
        return 'homeowner';
      case AppRole.independentProvider:
        return 'independent_provider';
      case AppRole.company:
        return 'company';
      case AppRole.companyTechnician:
        return 'company_technician';
      case AppRole.admin:
        return 'admin';
    }
  }

  /// The route path segment for this role's home screen.
  String get homeRoute {
    switch (this) {
      case AppRole.homeowner:
        return '/home/customer';
      case AppRole.independentProvider:
        return '/home/technician';
      case AppRole.company:
        return '/home/company';
      case AppRole.companyTechnician:
        return '/home/company-technician';
      case AppRole.admin:
        return '/home/admin';
    }
  }

  /// Parses a backend string value to an [AppRole]. Defaults to [AppRole.homeowner].
  static AppRole fromValue(String? value) {
    return AppRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => AppRole.homeowner,
    );
  }
}
