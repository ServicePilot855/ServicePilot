import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/admin/providers/admin_provider_approval_provider.dart';
import 'package:service_pilot/features/admin/screens/provider_review_screen.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/screens/provider_detail_screen.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';
import 'package:service_pilot/shared/home/admin_home.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const adminUser = UserModel(
    id: 'admin-01',
    fullName: 'Admin User',
    email: 'admin@servicepilot.app',
    phoneNumber: '+855 12 000 001',
    role: AppRole.admin,
    status: 'active',
  );

  const customerUser = UserModel(
    id: 'cust-01',
    fullName: 'Sok Dara',
    email: 'customer@example.com',
    phoneNumber: '+855 12 111 222',
    role: AppRole.homeowner,
    status: 'active',
  );

  Widget buildAdminTestApp({
    required IProviderService service,
    required UserModel? actor,
    String initialLocation = '/home/admin',
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/home/admin',
          builder: (_, __) => const AdminHome(),
        ),
        GoRoute(
          path: '/admin/providers/:providerId',
          builder: (_, state) {
            final id = state.pathParameters['providerId'] ?? '';
            final extra = state.extra as ProviderModel?;
            return ProviderReviewScreen(
              providerId: id,
              initialProvider: extra,
            );
          },
        ),
        GoRoute(
          path: '/providers/:providerId',
          builder: (_, state) {
            final id = state.pathParameters['providerId'] ?? '';
            final extra = state.extra as ProviderModel?;
            return ProviderDetailScreen(
              providerId: id,
              initialProvider: extra,
            );
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        providerServiceProvider.overrideWithValue(service),
        activeAdminActorProvider.overrideWithValue(actor),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  group('SCRUM-94 / ADM-2 (SCRUM-163 & SCRUM-164): Admin Provider Review & Approval Widget Tests', () {
    testWidgets(
      'AdminHome displays pending provider applications and navigates to ProviderReviewScreen',
      (tester) async {
        final service = ProviderService();
        await tester.pumpWidget(
          buildAdminTestApp(
            service: service,
            actor: adminUser,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pending provider applications'), findsOneWidget);
        expect(find.text('Sokha Pich'), findsOneWidget);
        expect(find.text('Mekong Home Repair Co., Ltd.'), findsOneWidget);

        // Tap pending provider card -> navigates to ProviderReviewScreen
        await tester.tap(
          find.byKey(const Key('admin_pending_provider_prov-pending-sokha')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Review provider'), findsOneWidget);
        expect(
          find.byKey(const Key('admin_provider_pending_notice')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('admin_approve_provider_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'approving a pending provider on ProviderReviewScreen updates status to Approved & active and makes it bookable',
      (tester) async {
        final service = ProviderService();
        await tester.pumpWidget(
          buildAdminTestApp(
            service: service,
            actor: adminUser,
            initialLocation: '/admin/providers/prov-pending-sokha',
          ),
        );
        await tester.pumpAndSettle();

        // Initially pending
        expect(find.text('Pending verification'), findsOneWidget);
        final approveBtn = find.byKey(
          const Key('admin_approve_provider_button'),
        );
        expect(approveBtn, findsOneWidget);

        // Tap Approve provider
        await tester.tap(approveBtn);
        await tester.pumpAndSettle();

        // Shows approved status notice & chip
        expect(
          find.byKey(const Key('admin_provider_approved_notice')),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Sokha Pich is now approved, active, and eligible for customer bookings.',
          ),
          findsOneWidget,
        );
        expect(find.text('Approved & active'), findsOneWidget);
        expect(
          find.byKey(const Key('admin_approve_provider_button')),
          findsNothing,
        );

        // Tap Preview customer profile -> verify provider is now bookable on customer profile
        final previewBtn = find.byKey(
          const Key('admin_preview_customer_profile_button'),
        );
        expect(previewBtn, findsOneWidget);
        await tester.tap(previewBtn);
        await tester.pumpAndSettle();

        expect(find.text('Provider profile'), findsOneWidget);
        expect(find.text('Continue to booking'), findsOneWidget);
      },
    );

    testWidgets(
      'non-admin account is denied access on both AdminHome and ProviderReviewScreen',
      (tester) async {
        final service = ProviderService();
        await tester.pumpWidget(
          buildAdminTestApp(
            service: service,
            actor: customerUser,
            initialLocation: '/admin/providers/prov-pending-sokha',
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('admin_access_denied_hero')),
          findsOneWidget,
        );
        expect(find.text('Admin access required'), findsOneWidget);
        expect(
          find.byKey(const Key('admin_approve_provider_button')),
          findsNothing,
        );

        // Provider remains pending
        final pending = await service.getProviderById('prov-pending-sokha');
        expect(pending?.isPendingVerification, isTrue);
      },
    );
  });
}
