import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/screens/splash_screen.dart';
import 'package:service_pilot/features/auth/screens/role_select_screen.dart';
import 'package:service_pilot/features/auth/screens/login_screen.dart';
import 'package:service_pilot/features/auth/screens/register_customer_screen.dart';
import 'package:service_pilot/features/auth/screens/register_technician_screen.dart';
import 'package:service_pilot/features/auth/screens/register_company_screen.dart';
import 'package:service_pilot/features/auth/screens/technician_activation_screen.dart';
import 'package:service_pilot/features/auth/screens/forgot_password_screen.dart';
import 'package:service_pilot/features/auth/screens/reset_password_screen.dart';
import 'package:service_pilot/shared/home/customer_home.dart';
import 'package:service_pilot/shared/home/technician_home.dart';
import 'package:service_pilot/shared/home/company_home.dart';
import 'package:service_pilot/shared/home/company_technician_home.dart';
import 'package:service_pilot/shared/home/admin_home.dart';

/// Provides the [GoRouter] instance to the widget tree.
///
/// The router uses the current [AuthState] to guard home routes and
/// redirect unauthenticated users to `/login`.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state changes for redirect logic.
  final authNotifier = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen<AuthState>(authProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,

    // ── Redirect guard ────────────────────────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authNotifier.value;
      final isAuthenticated = authState is AuthStateAuthenticated;
      final isGoingToHome = state.matchedLocation.startsWith('/home');
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSplash = state.matchedLocation == '/splash';

      // Let the splash screen handle its own routing.
      if (isGoingToSplash) return null;

      // Unauthenticated users cannot access home screens.
      if (!isAuthenticated && isGoingToHome) return '/login';

      // Authenticated users are redirected away from /login to their home.
      if (isAuthenticated && isGoingToLogin) {
        return (authState).user.role.homeRoute;
      }

      return null; // No redirect needed.
    },

    // ── Routes ────────────────────────────────────────────────────────────
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role-select',
        builder: (_, __) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: '/register/customer',
        builder: (_, __) => const RegisterCustomerScreen(),
      ),
      GoRoute(
        path: '/register/technician',
        builder: (_, __) => const RegisterTechnicianScreen(),
      ),
      GoRoute(
        path: '/register/company',
        builder: (_, __) => const RegisterCompanyScreen(),
      ),
      GoRoute(
        path: '/activate',
        builder: (_, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          final email = state.uri.queryParameters['email'];
          final company = state.uri.queryParameters['company'];
          return TechnicianActivationScreen(
            token: token,
            email: email,
            companyName: company,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),

      // ── Protected home routes ─────────────────────────────────────────
      GoRoute(
        path: '/home/customer',
        builder: (_, __) => const CustomerHome(),
      ),
      GoRoute(
        path: '/home/technician',
        builder: (_, __) => const TechnicianHome(),
      ),
      GoRoute(
        path: '/home/company',
        builder: (_, __) => const CompanyHome(),
      ),
      GoRoute(
        path: '/home/company-technician',
        builder: (_, __) => const CompanyTechnicianHome(),
      ),
      GoRoute(
        path: '/home/admin',
        builder: (_, __) => const AdminHome(),
      ),
    ],
  );
});
