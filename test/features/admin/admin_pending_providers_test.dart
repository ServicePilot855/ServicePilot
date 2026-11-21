import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/admin/providers/admin_provider.dart';
import 'package:service_pilot/features/admin/screens/admin_pending_providers_screen.dart';
import 'package:service_pilot/features/admin/services/admin_provider_service.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/widgets/provider_type_badge.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/home/admin_home.dart';

Widget _buildTestApp({
  required Widget child,
  required UserModel? currentUser,
  required IAdminProviderService adminService,
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(currentUser),
      adminProviderServiceProvider.overrideWithValue(adminService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  const adminUser = UserModel(
    id: 'admin-001',
    fullName: 'David Yeat',
    email: 'admin.david@servicepilot.app',
    phoneNumber: '+855 12 000 111',
    role: AppRole.admin,
    status: 'active',
  );

  const customerUser = UserModel(
    id: 'customer-001',
    fullName: 'Bora Chan',
    email: 'bora@example.com',
    phoneNumber: '+855 12 333 444',
    role: AppRole.homeowner,
    status: 'active',
  );

  const technicianUser = UserModel(
    id: 'tech-001',
    fullName: 'Sok Dara',
    email: 'tech.dara@example.com',
    phoneNumber: '+855 12 555 666',
    role: AppRole.independentProvider,
    status: 'active',
  );

  final samplePendingTech = ProviderModel(
    id: 'pending-tech-1',
    name: 'Sokunthea Keo',
    businessName: 'Keo Electrical & Cooling',
    type: ProviderType.independent,
    description: 'Electrician & Split AC Specialist',
    specialties: const ['Electrical Wiring', 'Inverter AC Diagnostics'],
    coverageAreas: const ['Toul Kork', 'Daun Penh'],
    serviceArea: 'Toul Kork, Daun Penh',
    phone: '+855 12 345 678',
    email: 'sokunthea.keo@example.com',
    status: 'pending_verification',
    isVerified: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  final samplePendingCompany = ProviderModel(
    id: 'pending-company-1',
    name: 'Phnom Penh Clean & Cool Co.',
    businessName: 'PP Clean & Cool Services Co., Ltd.',
    type: ProviderType.company,
    description: 'Commercial HVAC & plumbing contractor',
    specialties: const ['Commercial VRV', 'Pipe Jetting'],
    coverageAreas: const ['Chamkarmon', 'BKK1'],
    serviceArea: 'Chamkarmon, BKK1',
    phone: '+855 23 888 999',
    email: 'contact@cleanandcool.com.kh',
    status: 'pending_verification',
    isVerified: false,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  );

  group('SCRUM-93 / ADM-1: View Pending Provider Applications', () {
    testWidgets(
      'Admin sees list of pending applications with correct details and badges',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final mockService = AdminProviderService(
          initialProviders: [samplePendingTech, samplePendingCompany],
        );

        await tester.pumpWidget(
          _buildTestApp(
            child: const AdminPendingProvidersScreen(),
            currentUser: adminUser,
            adminService: mockService,
          ),
        );
        await tester.pumpAndSettle();

        // Screen title and pending count
        expect(find.text('Provider Applications'), findsOneWidget);
        expect(find.text('2 pending'), findsOneWidget);

        // Independent Technician
        expect(find.text('Sokunthea Keo'), findsOneWidget);
        expect(find.text('Keo Electrical & Cooling'), findsOneWidget);
        expect(find.textContaining('Independent'), findsOneWidget);
        expect(find.text('+855 12 345 678'), findsOneWidget);
        expect(find.text('sokunthea.keo@example.com'), findsOneWidget);
        expect(find.text('Electrical Wiring'), findsOneWidget);
        expect(find.text('Toul Kork, Daun Penh'), findsOneWidget);

        // Service Company
        expect(find.text('Phnom Penh Clean & Cool Co.'), findsOneWidget);
        expect(find.text('PP Clean & Cool Services Co., Ltd.'), findsOneWidget);
        expect(find.text('Repair company'), findsOneWidget);
        expect(find.byType(ProviderTypeBadge), findsNWidgets(2));
        expect(find.text('+855 23 888 999'), findsOneWidget);
        expect(find.text('contact@cleanandcool.com.kh'), findsOneWidget);
        expect(find.text('Chamkarmon, BKK1'), findsOneWidget);

        // Pending status badges
        expect(find.textContaining('Pending Verification'), findsNWidgets(2));
      },
    );

    testWidgets(
      'Empty state displays when no applications are pending',
      (tester) async {
        final mockService = AdminProviderService(initialProviders: []);

        await tester.pumpWidget(
          _buildTestApp(
            child: const AdminPendingProvidersScreen(),
            currentUser: adminUser,
            adminService: mockService,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'All provider applications have been reviewed. There are no accounts pending verification.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Role security: Non-admin customer is strictly blocked from the queue',
      (tester) async {
        final mockService = AdminProviderService(
          initialProviders: [samplePendingTech],
        );

        await tester.pumpWidget(
          _buildTestApp(
            child: const AdminPendingProvidersScreen(),
            currentUser: customerUser,
            adminService: mockService,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Access Restricted'), findsOneWidget);
        expect(
          find.text(
            'Access Restricted. Only platform administrators have permission to review provider applications.',
          ),
          findsOneWidget,
        );
        // Provider data must NOT be rendered
        expect(find.text('Sokunthea Keo'), findsNothing);
      },
    );

    testWidgets(
      'Role security: Technician is strictly blocked from the queue',
      (tester) async {
        final mockService = AdminProviderService(
          initialProviders: [samplePendingTech],
        );

        await tester.pumpWidget(
          _buildTestApp(
            child: const AdminPendingProvidersScreen(),
            currentUser: technicianUser,
            adminService: mockService,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Access Restricted'), findsOneWidget);
        expect(find.text('Sokunthea Keo'), findsNothing);
      },
    );

    testWidgets(
      'AdminHome displays Provider Applications action card with live pending count',
      (tester) async {
        final mockService = AdminProviderService(
          initialProviders: [samplePendingTech, samplePendingCompany],
        );

        await tester.pumpWidget(
          _buildTestApp(
            child: const AdminHome(),
            currentUser: adminUser,
            adminService: mockService,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Provider Applications'), findsOneWidget);
        expect(find.text('2 Pending'), findsOneWidget);
        expect(find.text('View Pending Applications'), findsOneWidget);
      },
    );
  });
}
