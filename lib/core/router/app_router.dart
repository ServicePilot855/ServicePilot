import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/admin/screens/provider_review_screen.dart';
import 'package:service_pilot/features/admin/screens/admin_pending_providers_screen.dart';
import 'package:service_pilot/features/auth/screens/splash_screen.dart';
import 'package:service_pilot/features/auth/screens/role_select_screen.dart';
import 'package:service_pilot/features/auth/screens/login_screen.dart';
import 'package:service_pilot/features/auth/screens/register_customer_screen.dart';
import 'package:service_pilot/features/auth/screens/register_technician_screen.dart';
import 'package:service_pilot/features/auth/screens/register_company_screen.dart';
import 'package:service_pilot/features/auth/screens/technician_activation_screen.dart';
import 'package:service_pilot/features/auth/screens/forgot_password_screen.dart';
import 'package:service_pilot/features/auth/screens/reset_password_screen.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/screens/booking_confirmation_screen.dart';
import 'package:service_pilot/features/bookings/screens/booking_history_screen.dart';
import 'package:service_pilot/features/bookings/screens/booking_tracking_screen.dart';
import 'package:service_pilot/features/bookings/screens/create_booking_screen.dart';
import 'package:service_pilot/features/bookings/screens/location_picker_screen.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/screens/company_profile_edit_screen.dart';
import 'package:service_pilot/features/providers/screens/provider_detail_screen.dart';
import 'package:service_pilot/features/providers/screens/provider_list_screen.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/screens/categories_screen.dart';
import 'package:service_pilot/features/services/screens/create_offering_screen.dart';
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
      final isGoingToAdmin = state.matchedLocation.startsWith('/home/admin') ||
          state.matchedLocation.startsWith('/admin');
      final isGoingToHome = state.matchedLocation.startsWith('/home') ||
          state.matchedLocation.startsWith('/categories') ||
          state.matchedLocation.startsWith('/providers') ||
          state.matchedLocation.startsWith('/bookings') ||
          state.matchedLocation.startsWith('/offerings') ||
          isGoingToAdmin;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSplash = state.matchedLocation == '/splash';

      // Let the splash screen handle its own routing.
      if (isGoingToSplash) return null;

      // Unauthenticated users cannot access home, category, booking, or admin screens.
      if (!isAuthenticated && isGoingToHome) return '/login';

      // Non-admin authenticated users cannot access Platform Admin routes (SCRUM-94 / ADM-2).
      if (isAuthenticated && isGoingToAdmin && !authState.user.isAdmin) {
        return authState.user.role.homeRoute;
      }

      if (isAuthenticated &&
          state.matchedLocation == '/home/company/profile' &&
          (!authState.user.isCompany || authState.user.isSuspended)) {
        return authState.user.role.homeRoute;
      }

      // Authenticated users are redirected away from /login to their home.
      if (isAuthenticated && isGoingToLogin) {
        return (authState).user.role.homeRoute;
      }

      // Restrict /offerings/create to providers and companies only (Issue 2)
      if (isAuthenticated && state.matchedLocation.startsWith('/offerings')) {
        final role = (authState).user.role;
        if (role != AppRole.independentProvider &&
            role != AppRole.company &&
            role != AppRole.admin) {
          return role.homeRoute;
        }
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

      // ── Categories & Services (US-09) ──────────────────────────────────
      GoRoute(
        path: '/categories',
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/offerings/create',
        builder: (_, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          final providerId = state.uri.queryParameters['providerId'];
          return CreateOfferingScreen(
            initialCategoryId: categoryId,
            initialProviderId: providerId,
          );
        },
      ),
      GoRoute(
        path: '/categories/:categoryId/providers',
        builder: (_, state) {
          final categoryId = state.pathParameters['categoryId'] ?? '';
          final category = state.extra as CategoryModel?;
          return ProviderListScreen(
            categoryId: categoryId,
            category: category,
          );
        },
      ),
      // ── Provider Details & Profiles (US-11) ───────────────────────────
      GoRoute(
        path: '/providers/:providerId',
        builder: (_, state) {
          final providerId = state.pathParameters['providerId'] ?? '';
          final provider = state.extra as ProviderModel?;
          return ProviderDetailScreen(
            providerId: providerId,
            initialProvider: provider,
          );
        },
      ),
      // ── Booking request (US-12 / OFFER-2) ─────────────────────────────
      GoRoute(
        path: '/providers/:providerId/book',
        builder: (_, state) {
          final providerId = state.pathParameters['providerId'] ?? '';
          final provider = state.extra as ProviderModel?;
          final serviceTitle = state.uri.queryParameters['serviceTitle'];
          final offeringId = state.uri.queryParameters['offeringId'];
          final isQuoteRequired =
              state.uri.queryParameters['pricingMode'] == 'quoteRequired';
          return CreateBookingScreen(
            providerId: providerId,
            initialProvider: provider,
            initialServiceTitle: serviceTitle,
            initialOfferingId: offeringId,
            isQuoteRequired: isQuoteRequired,
          );
        },
      ),
      GoRoute(
        path: '/providers/:providerId/book/location',
        builder: (_, state) => LocationPickerScreen(
          initial: state.extra as LatLng?,
        ),
      ),
      GoRoute(
        path: '/bookings/:bookingId/sent',
        builder: (_, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          final booking = state.extra as BookingModel?;
          return BookingConfirmationScreen(
            bookingId: bookingId,
            booking: booking,
          );
        },
      ),

      // ── Booking History (US-15 / SCRUM-46) ────────────────────────────
      GoRoute(
        path: '/bookings/history',
        builder: (_, __) => const BookingHistoryScreen(),
      ),

      // ── Bookings & Cancellation (US-13 / US-14) ───────────────────────
      GoRoute(
        path: '/bookings/:bookingId',
        builder: (_, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          final booking = state.extra as BookingModel?;
          return BookingTrackingScreen(
            bookingId: bookingId,
            initialBooking: booking,
          );
        },
      ),

      // ── Admin: Pending Provider Applications (ADM-1 / SCRUM-93) ───────
      GoRoute(
        path: '/admin/providers/pending',
        builder: (_, __) => const AdminPendingProvidersScreen(),
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
        routes: [
          GoRoute(
            path: 'profile',
            builder: (_, __) => const CompanyProfileEditScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/home/company-technician',
        builder: (_, __) => const CompanyTechnicianHome(),
      ),
      GoRoute(
        path: '/home/admin',
        builder: (_, __) => const AdminHome(),
      ),
      GoRoute(
        path: '/admin/providers/:providerId',
        builder: (_, state) {
          final providerId = state.pathParameters['providerId'] ?? '';
          final provider = state.extra as ProviderModel?;
          return ProviderReviewScreen(
            providerId: providerId,
            initialProvider: provider,
          );
        },
      ),
    ],
  );
});
