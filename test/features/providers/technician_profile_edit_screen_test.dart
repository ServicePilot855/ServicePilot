import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/router/app_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/services/independent_profile_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

class _SignedIn extends AuthNotifier {
  _SignedIn(this.user);

  final UserModel user;

  @override
  AuthState build() => AuthStateAuthenticated(user);
}

void main() {
  const owner = UserModel(
    id: 'tech-a',
    fullName: 'Virak Chan',
    email: 'virak@example.com',
    phoneNumber: '+85587654321',
    role: AppRole.independentProvider,
    status: 'active',
  );

  late FakeFirebaseFirestore firestore;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('providers').doc(owner.id).set({
      'id': owner.id,
      'providerType': 'independent',
      'name': 'Virak Chan',
      'fullName': 'Virak Chan',
      'serviceArea': 'Toul Kork',
      'status': 'active',
    });
  });

  Future<ProviderContainer> openApp(
    WidgetTester tester,
    UserModel user, {
    String path = '/home/technician',
    Locale locale = const Locale('en'),
    double width = 360,
  }) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      authProvider.overrideWith(() => _SignedIn(user)),
      independentProfileServiceProvider.overrideWithValue(
        IndependentProfileService(firestore: firestore),
      ),
    ]);
    final router = container.read(appRouterProvider);
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    router.go(path);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
      'technician home opens a prefilled editor and saves corrected details',
      (tester) async {
    await openApp(tester, owner);
    await tester.tap(find.text('Edit technician profile'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(tester.widget<TextFormField>(fields.first).controller?.text,
        'Virak Chan');
    expect(tester.widget<TextFormField>(fields.at(2)).controller?.text,
        'Toul Kork');

    await tester.enterText(fields.first, 'Virak Chan Senior');
    await tester.enterText(fields.at(2), 'Sen Sok');
    final telegram = fields.at(3);
    await tester.ensureVisible(telegram);
    await tester.enterText(telegram, 'https://example.com');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a link like https://t.me/virakchan.'),
        findsOneWidget);

    await tester.enterText(telegram, 'https://t.me/virakchan');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Technician profile saved.'), findsOneWidget);

    final profile = await firestore.collection('providers').doc(owner.id).get();
    expect(profile.data(), containsPair('serviceArea', 'Sen Sok'));
    expect(profile.data(), containsPair('name', 'Virak Chan Senior'));
    expect(profile.data(),
        containsPair('telegramUrl', 'https://t.me/virakchan'));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Virak Chan Senior'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Khmer save action stays above the keyboard at 320dp',
      (tester) async {
    await openApp(
      tester,
      owner,
      path: '/home/technician/profile',
      locale: const Locale('km'),
      width: 320,
    );
    expect(find.text('កែព័ត៌មានជាងជួសជុល'), findsOneWidget);
    final save = find.text('រក្សាទុកការកែប្រែ');
    expect(save, findsOneWidget);

    final lastField = find.byType(TextFormField).last;
    await tester.ensureVisible(lastField);
    await tester.showKeyboard(lastField);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(save).dy, lessThan(400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a company technician or homeowner cannot open the editor route',
      (tester) async {
    final container = await openApp(
      tester,
      owner.copyWith(role: AppRole.companyTechnician),
      path: '/home/technician/profile',
    );
    expect(
      container
          .read(appRouterProvider)
          .routeInformationProvider
          .value
          .uri
          .path,
      '/home/company-technician',
    );
    expect(find.byType(TextFormField), findsNothing);
  });
}
