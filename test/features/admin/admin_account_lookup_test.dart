import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/router/app_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/admin/screens/admin_account_lookup_screen.dart';
import 'package:service_pilot/features/admin/services/admin_account_lookup_service.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/l10n/l10n.dart';

const _admin = UserModel(
  id: 'admin-1',
  fullName: 'Demo Admin',
  email: 'admin@example.test',
  phoneNumber: '',
  role: AppRole.admin,
  status: 'active',
);

class _SignedIn extends AuthNotifier {
  _SignedIn(this.user);

  final UserModel user;

  @override
  AuthState build() => AuthStateAuthenticated(user);

  @override
  Future<void> checkAuthStatus() async {}
}

void main() {
  Widget app({
    required UserModel user,
    required AdminAccountLookupService service,
    Locale locale = const Locale('en'),
  }) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _SignedIn(user)),
        providerServiceProvider.overrideWithValue(ProviderService(initialProviders: [])),
        adminAccountLookupServiceProvider.overrideWithValue(service),
      ],
      child: Consumer(
        builder: (_, ref, __) => MaterialApp.router(
          routerConfig: ref.watch(appRouterProvider),
          locale: locale,
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
        ),
      ),
    );
  }

  AdminAccountLookupService service(MockClient client) {
    addTearDown(client.close);
    return AdminAccountLookupService(
      client: client,
      projectId: 'demo-servicepilot',
      origin: Uri.https('firestore.googleapis.com'),
      readIdToken: (_) async => 'fixture-token',
    );
  }

  testWidgets(
      'admin finds the two saved fields and gets a separate empty result',
      (tester) async {
    final requests = <http.Request>[];
    await tester.pumpWidget(app(
      user: _admin,
      service: service(MockClient((request) async {
        requests.add(request);
        final response = request.body.contains('/users/known-user')
            ? '''
              [{"document":{"fields":{
                "role":{"stringValue":"company_technician"},
                "status":{"stringValue":"suspended"}
              }}}]
              '''
            : '[{"readTime":"2026-11-28T00:00:00Z"}]';
        return http.Response(response, 200);
      })),
    ));

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find an account'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    final input = find.byKey(const Key('admin_account_id'));
    final search = find.text('Search');
    await tester.tap(search);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid account ID.'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.enterText(input, ' known-user ');
    await tester.tap(search);
    await tester.pumpAndSettle();
    expect(find.text('Role: Company Technician'), findsOneWidget);
    expect(find.text('Status: Suspended'), findsOneWidget);
    final request = requests.single;
    expect(request.headers['authorization'], 'Bearer fixture-token');
    expect(request.url.path,
        '/v1/projects/demo-servicepilot/databases/(default)/documents:runQuery');
    final query = jsonDecode(request.body)['structuredQuery'];
    expect(query['select']['fields'], [
      {'fieldPath': 'role'},
      {'fieldPath': 'status'},
    ]);
    expect(query['where']['fieldFilter']['value']['referenceValue'],
        'projects/demo-servicepilot/databases/(default)/documents/users/known-user');

    await tester.enterText(input, 'missing');
    await tester.tap(search);
    await tester.pumpAndSettle();
    expect(find.text('No account found for this ID.'), findsOneWidget);
    expect(find.text('Role: Company Technician'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a regular user is redirected away from an account lookup URL',
      (tester) async {
    await tester.pumpWidget(app(
      user: _admin.copyWith(
          role: AppRole.independentProvider, status: 'suspended'),
      service: service(
          MockClient((_) async => throw StateError('Unexpected lookup'))),
    ));

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(AdminAccountLookupScreen.path);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/home/technician');
    expect(find.byType(AdminAccountLookupScreen), findsNothing);
  });

  testWidgets(
      'shows a failed search in Khmer without exposing response content',
      (tester) async {
    await tester.pumpWidget(app(
      user: _admin,
      locale: const Locale('km'),
      service: service(
          MockClient((_) async => http.Response('server details', 503))),
    ));
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(AdminAccountLookupScreen.path);
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AdminAccountLookupScreen)),
    )!;
    await tester.enterText(find.byKey(const Key('admin_account_id')), 'known');
    await tester.tap(find.text(l10n.adminAccountLookupSearch));
    await tester.pumpAndSettle();
    expect(find.text(l10n.adminAccountLookupError), findsOneWidget);
    expect(find.text('server details'), findsNothing);
  });
}
