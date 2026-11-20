import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/screens/provider_detail_screen.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/services/screens/categories_screen.dart';
import 'package:service_pilot/main.dart';

class _SignedInCustomer extends AuthNotifier {
  @override
  AuthState build() => const AuthStateAuthenticated(
        UserModel(
          id: 'customer',
          fullName: 'Test Customer',
          email: 'customer@example.test',
          phoneNumber: '123',
          role: AppRole.homeowner,
          status: 'active',
        ),
      );
}

class _FlakyProviderService extends ProviderService {
  _FlakyProviderService() : super(initialProviders: const []);

  int calls = 0;

  @override
  Future<List<ProviderModel>> getProviders({
    String? categoryId,
    bool activeOnly = true,
  }) async {
    if (++calls == 1) throw StateError('offline');
    return super.getProviders(categoryId: categoryId, activeOnly: activeOnly);
  }
}

void main() {
  Future<void> open(
    WidgetTester tester,
    String path, {
    IProviderService? service,
    bool signedIn = true,
  }) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.defaultRouteNameTestValue = path;
    addTearDown(dispatcher.clearDefaultRouteNameTestValue);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        if (signedIn) authProvider.overrideWith(_SignedInCustomer.new),
        if (service != null) providerServiceProvider.overrideWithValue(service),
      ],
      child: const ServicePilotApp(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'category opens eligible providers and their full booking profile',
      (tester) async {
    final service = ProviderService(initialProviders: const [
      ProviderModel(
        id: 'company-1',
        name: 'Test Repair Company',
        type: ProviderType.company,
        serviceArea: 'Toul Kork',
        categoryIds: ['cat-plumbing'],
      ),
      ProviderModel(
        id: 'technician-1',
        name: 'Test Technician',
        coverageAreas: ['Sen Sok'],
        categoryIds: ['cat-plumbing'],
      ),
      ProviderModel(
        id: 'pending-1',
        name: 'Pending Provider',
        categoryIds: ['cat-plumbing'],
        status: 'pending_verification',
      ),
      ProviderModel(
        id: 'electrical-1',
        name: 'Electrical Provider',
        categoryIds: ['cat-electrical'],
      ),
    ]);
    await open(tester, '/categories', service: service);

    await tester.tap(find.text('Plumbing & Drainage'));
    await tester.pumpAndSettle();
    expect(find.text('Test Repair Company'), findsOneWidget);
    expect(find.text('Repair Company'), findsOneWidget);
    expect(find.text('Toul Kork'), findsOneWidget);
    expect(find.text('Test Technician'), findsOneWidget);
    expect(find.text('Independent'), findsOneWidget);
    expect(find.text('Sen Sok'), findsOneWidget);
    expect(find.text('Pending Provider'), findsNothing);
    expect(find.text('Electrical Provider'), findsNothing);

    await tester.tap(find.text('Test Repair Company'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ProviderDetailScreen>(find.byType(ProviderDetailScreen))
          .providerId,
      'company-1',
    );
    expect(find.text('Provider Profile'), findsOneWidget);
    expect(find.text('Book Service'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Test Technician'), findsOneWidget);
  });

  testWidgets('a failed directory request can be retried', (tester) async {
    final service = _FlakyProviderService();
    await open(tester, '/categories/cat-plumbing/providers', service: service);

    expect(find.text('Couldn’t load providers.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No providers are available for this category yet.'),
        findsOneWidget);
    expect(service.calls, 2);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoriesScreen), findsOneWidget);
  });

  testWidgets('a signed-out visitor cannot open a provider profile by URL',
      (tester) async {
    await open(tester, '/providers/company-1', signedIn: false);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(ProviderDetailScreen), findsNothing);
  });
}
