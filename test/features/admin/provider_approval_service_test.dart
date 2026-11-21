import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/services/firestore_provider_service.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const adminUser = UserModel(
    id: 'admin-01',
    fullName: 'Platform Administrator',
    email: 'admin@servicepilot.app',
    phoneNumber: '+855 12 000 001',
    role: AppRole.admin,
    status: 'active',
  );

  const homeownerUser = UserModel(
    id: 'cust-01',
    fullName: 'Sok Dara',
    email: 'customer@example.com',
    phoneNumber: '+855 12 111 222',
    role: AppRole.homeowner,
    status: 'active',
  );

  const independentProviderUser = UserModel(
    id: 'prov-pending-sokha',
    fullName: 'Sokha Pich',
    email: 'sokha.pich@servicepilot.kh',
    phoneNumber: '+855 96 445 566',
    role: AppRole.independentProvider,
    status: 'pending_verification',
  );

  const companyUser = UserModel(
    id: 'comp-01',
    fullName: 'Channary Rath',
    email: 'contact@mekonghomerepair.kh',
    phoneNumber: '+855 23 555 789',
    role: AppRole.company,
    status: 'pending_verification',
  );

  const companyTechUser = UserModel(
    id: 'tech-01',
    fullName: 'Borey Nhem',
    email: 'tech@mekonghomerepair.kh',
    phoneNumber: '+855 15 999 888',
    role: AppRole.companyTechnician,
    status: 'active',
  );

  group('SCRUM-94 / ADM-2 (SCRUM-162 & SCRUM-164): Provider Approval & Bookability Tests', () {
    late ProviderService providerService;
    late FirestoreProviderService firestoreProviderService;

    setUp(() {
      providerService = ProviderService();
      firestoreProviderService = FirestoreProviderService();
    });

    test(
      'pending verification provider is excluded from customer discovery and is not bookable before approval',
      () async {
        final pending = await providerService.getProviderById(
          'prov-pending-sokha',
        );
        expect(pending, isNotNull);
        expect(pending!.status, equals('pending_verification'));
        expect(pending.isPendingVerification, isTrue);
        expect(pending.isApprovedAndActive, isFalse);
        expect(pending.canAcceptBookings, isFalse);

        // Must not appear in active customer discovery lists
        final activeProviders = await providerService.getProviders();
        expect(
          activeProviders.any((p) => p.id == 'prov-pending-sokha'),
          isFalse,
        );

        final acCategoryProviders = await providerService
            .getProvidersByCategory('cat-ac');
        expect(
          acCategoryProviders.any((p) => p.id == 'prov-pending-sokha'),
          isFalse,
        );
      },
    );

    test(
      'authorized admin approves a Pending Verification independent provider and it becomes discoverable and bookable',
      () async {
        final approved = await providerService.approveProvider(
          providerId: 'prov-pending-sokha',
          actor: adminUser,
        );

        expect(approved.status, equals('active'));
        expect(approved.isVerified, isTrue);
        expect(approved.isPendingVerification, isFalse);
        expect(approved.isApprovedAndActive, isTrue);
        expect(approved.canAcceptBookings, isTrue);
        expect(approved.updatedAt, isNotNull);

        // Persisted record reflects approved status
        final stored = await providerService.getProviderById(
          'prov-pending-sokha',
        );
        expect(stored?.status, equals('active'));
        expect(stored?.canAcceptBookings, isTrue);

        // Now eligible for customer discovery in AC category
        final acProviders = await providerService.getProvidersByCategory(
          'cat-ac',
        );
        expect(
          acProviders.any((p) => p.id == 'prov-pending-sokha'),
          isTrue,
        );

        // Removed from pending queue
        final remainingPending = await providerService.getPendingProviders(
          actor: adminUser,
        );
        expect(
          remainingPending.any((p) => p.id == 'prov-pending-sokha'),
          isFalse,
        );
      },
    );

    test(
      'authorized admin approves a Pending Verification company provider in FirestoreProviderService',
      () async {
        final beforeList = await firestoreProviderService
            .getProvidersByCategory('cat-plumbing');
        expect(
          beforeList.any((p) => p.id == 'prov-pending-mekong-co'),
          isFalse,
        );

        final approved = await firestoreProviderService.approveProvider(
          providerId: 'prov-pending-mekong-co',
          actor: adminUser,
        );

        expect(approved.status, equals('active'));
        expect(approved.isVerified, isTrue);
        expect(approved.isCompany, isTrue);
        expect(approved.canAcceptBookings, isTrue);

        final afterList = await firestoreProviderService.getProvidersByCategory(
          'cat-plumbing',
        );
        expect(
          afterList.any((p) => p.id == 'prov-pending-mekong-co'),
          isTrue,
        );
      },
    );

    test(
      'approved provider that is currently unavailable is discoverable but not bookable until available',
      () async {
        final service = ProviderService(
          initialProviders: const [
            ProviderModel(
              id: 'prov-pending-unavailable',
              name: 'Nary Chan',
              type: ProviderType.independent,
              categoryIds: ['cat-electrical'],
              isAvailable: false,
              unavailableReason: 'On site at another repair job',
              isVerified: false,
              status: 'pending_verification',
            ),
          ],
        );

        final approved = await service.approveProvider(
          providerId: 'prov-pending-unavailable',
          actor: adminUser,
        );

        expect(approved.isApprovedAndActive, isTrue);
        // Because isAvailable == false, canAcceptBookings remains false per ADM-2 AC ("when available")
        expect(approved.canAcceptBookings, isFalse);

        final discovered = await service.getProvidersByCategory(
          'cat-electrical',
        );
        expect(
          discovered.any((p) => p.id == 'prov-pending-unavailable'),
          isTrue,
        );
      },
    );

    test(
      'non-admin roles (homeowner, independent provider, company, company technician, unauthenticated) are denied and leave record unchanged',
      () async {
        final unauthorizedActors = <UserModel?>[
          null,
          homeownerUser,
          independentProviderUser,
          companyUser,
          companyTechUser,
        ];

        for (final actor in unauthorizedActors) {
          expect(
            () => providerService.approveProvider(
              providerId: 'prov-pending-sokha',
              actor: actor,
            ),
            throwsA(isA<UnauthorizedProviderApprovalException>()),
          );

          expect(
            () => providerService.getPendingProviders(actor: actor),
            throwsA(isA<UnauthorizedProviderApprovalException>()),
          );
        }

        // Verify the pending provider record was left completely unchanged
        final unchanged = await providerService.getProviderById(
          'prov-pending-sokha',
        );
        expect(unchanged?.status, equals('pending_verification'));
        expect(unchanged?.isVerified, isFalse);
        expect(unchanged?.canAcceptBookings, isFalse);
      },
    );

    test(
      'cannot approve an already active provider or nonexistent provider',
      () async {
        expect(
          () => providerService.approveProvider(
            providerId: 'prov-dara-ac',
            actor: adminUser,
          ),
          throwsA(isA<InvalidProviderApprovalStateException>()),
        );

        expect(
          () => providerService.approveProvider(
            providerId: 'prov-does-not-exist',
            actor: adminUser,
          ),
          throwsA(isA<ProviderNotFoundException>()),
        );
      },
    );
  });
}
