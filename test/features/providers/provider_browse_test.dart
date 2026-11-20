import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/provider_directory.dart';
import 'package:service_pilot/features/providers/screens/provider_list_screen.dart';
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

void main() {
  Future<void> open(
    WidgetTester tester,
    String path,
    ProviderDirectory directory, {
    bool signedIn = true,
  }) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.defaultRouteNameTestValue = path;
    addTearDown(dispatcher.clearDefaultRouteNameTestValue);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        if (signedIn) authProvider.overrideWith(_SignedInCustomer.new),
        providerDirectoryProvider.overrideWithValue(directory),
      ],
      child: const ServicePilotApp(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('category opens eligible providers and a card opens its profile',
      (tester) async {
    const company = {
      'uid': 'company-1',
      'providerName': 'Test Repair Company',
      'providerType': 'COMPANY',
      'providerStatus': 'ACTIVE',
      'serviceArea': 'Toul Kork',
    };
    const technician = {
      'uid': 'technician-1',
      'providerName': 'Test Technician',
      'providerType': 'INDEPENDENT',
      'providerStatus': 'ACTIVE',
      'serviceArea': 'Sen Sok',
    };
    final directory = ProviderDirectory((operation, variables) async {
      if (operation == 'ListCategoryProviders') {
        expect(variables, {'categoryKey': 'cat-plumbing'});
        return {
          'providers': [company, technician]
        };
      }
      expect(operation, 'GetActiveProvider');
      expect(variables, {'providerId': 'company-1'});
      return {
        'providers': [company]
      };
    });
    await open(tester, '/categories', directory);

    await tester.tap(find.text('Plumbing & Drainage'));
    await tester.pumpAndSettle();
    expect(find.text('Test Repair Company'), findsOneWidget);
    expect(find.text('Company'), findsOneWidget);
    expect(find.text('Toul Kork'), findsOneWidget);
    expect(find.text('Test Technician'), findsOneWidget);
    expect(find.text('Independent'), findsOneWidget);
    expect(find.text('Sen Sok'), findsOneWidget);

    await tester.tap(find.text('Test Repair Company'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ProviderProfileScreen>(find.byType(ProviderProfileScreen))
          .providerId,
      'company-1',
    );
    expect(find.text('Provider profile'), findsOneWidget);
    expect(find.text('Test Repair Company'), findsOneWidget);
    expect(find.text('Test Technician'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Test Technician'), findsOneWidget);
  });

  testWidgets('a failed directory request can be retried', (tester) async {
    var calls = 0;
    final directory = ProviderDirectory((_, __) async {
      if (++calls == 1) throw StateError('offline');
      return {'providers': []};
    });
    await open(tester, '/categories/cat-plumbing/providers', directory);

    expect(find.text('Couldn’t load providers.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No providers are available for this category yet.'),
        findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('a signed-out visitor cannot open a provider profile by URL',
      (tester) async {
    var requested = false;
    final directory = ProviderDirectory((_, __) async {
      requested = true;
      return {'providers': []};
    });
    await open(tester, '/providers/company-1', directory, signedIn: false);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(requested, isFalse);
  });
}
