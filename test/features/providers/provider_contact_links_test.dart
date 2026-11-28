import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/cart/models/cart_state.dart';
import 'package:service_pilot/features/cart/providers/cart_provider.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/screens/provider_detail_screen.dart';
import 'package:service_pilot/features/providers/services/provider_contact_links.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/l10n/app_localizations.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';

const _telegram = 'https://t.me/company_a';
const _messenger = 'https://m.me/company_a';

ProviderModel _provider({
  String? telegramUrl,
  String? messengerUrl,
  String status = 'active',
  bool isVerified = true,
}) =>
    ProviderModel(
      id: 'company-a',
      name: 'Company A',
      type: ProviderType.company,
      status: status,
      isVerified: isVerified,
      telegramUrl: telegramUrl,
      messengerUrl: messengerUrl,
    );

class _Harness {
  final opened = <Uri>[];
  final routes = <String>[];
  bool launchResult = true;
  late final CartNotifier cart;

  Widget build(ProviderModel provider, {Locale? locale}) {
    cart = CartNotifier()
      ..addOffering(
        const OfferingModel(
          id: 'offering-1',
          providerId: 'company-a',
          providerName: 'Company A',
          categoryId: 'plumbing',
          title: 'Fix a leaking tap',
          description: 'Replace the washer.',
          pricingMode: OfferingPricingMode.fixed,
          price: 25,
        ),
        providerName: 'Company A',
      );

    final router = GoRouter(
      initialLocation: '/providers/company-a',
      routes: [
        GoRoute(
          path: '/providers/:providerId',
          builder: (_, state) {
            routes.add(state.uri.toString());
            return ProviderDetailScreen(
              providerId: state.pathParameters['providerId']!,
            );
          },
          routes: [
            GoRoute(
              path: 'book',
              builder: (_, state) {
                routes.add(state.uri.toString());
                return const Scaffold(body: Text('Booking page'));
              },
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        providerServiceProvider
            .overrideWithValue(ProviderService(initialProviders: [provider])),
        cartProvider.overrideWith((ref) => cart),
        externalLinkLauncherProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return launchResult;
        }),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}

void _setViewport(WidgetTester tester, {double width = 800}) {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

final _telegramButton = find.byKey(const Key('provider_contact_telegram'));
final _messengerButton = find.byKey(const Key('provider_contact_messenger'));

void main() {
  group('DISC-2 providerContactLinks', () {
    test('returns valid saved links with their channel', () {
      final links = providerContactLinks(
        _provider(telegramUrl: ' $_telegram ', messengerUrl: _messenger),
      );
      expect(
        links.map((link) => (link.channel, link.uri.toString())),
        [
          (ProviderContactChannel.telegram, _telegram),
          (ProviderContactChannel.messenger, _messenger),
        ],
      );
    });

    test('leaves out missing, blank and malformed links', () {
      for (final (telegram, messenger) in [
        (null, null),
        ('', '   '),
        ('https://t.me.example.com/company_a', 'http://m.me/company_a'),
        ('https://m.me/company_a', 'https://t.me/company_a'),
        ('javascript:alert(1)', 'https://m.me/../evil'),
        ('https://t.me/a?next=https://evil.test', 'https://m.me/'),
      ]) {
        expect(
          providerContactLinks(
            _provider(telegramUrl: telegram, messengerUrl: messenger),
          ),
          isEmpty,
          reason: 'telegram: $telegram, messenger: $messenger',
        );
      }
    });
  });

  group('DISC-2 provider profile contact actions', () {
    testWidgets('each saved link opens externally with the exact saved URL',
        (tester) async {
      _setViewport(tester);
      final harness = _Harness();
      await tester.pumpWidget(harness.build(
        _provider(telegramUrl: _telegram, messengerUrl: _messenger),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Contact links'), findsOneWidget);
      expect(find.widgetWithText(SpSecondaryButton, 'Message on Telegram'),
          findsOneWidget);
      expect(find.widgetWithText(SpSecondaryButton, 'Message on Messenger'),
          findsOneWidget);
      expect(find.textContaining('Opens outside ServicePilot'), findsOneWidget);

      await tester.ensureVisible(_telegramButton);
      await tester.tap(_telegramButton);
      await tester.pumpAndSettle();
      await tester.ensureVisible(_messengerButton);
      await tester.tap(_messengerButton);
      await tester.pumpAndSettle();

      expect(harness.opened, [Uri.parse(_telegram), Uri.parse(_messenger)]);
    });

    testWidgets(
        'opening a link leaves the cart, its prices and the route unchanged',
        (tester) async {
      _setViewport(tester);
      final harness = _Harness();
      await tester.pumpWidget(harness.build(_provider(telegramUrl: _telegram)));
      await tester.pumpAndSettle();
      final CartState before = harness.cart.state;

      await tester.ensureVisible(_telegramButton);
      await tester.tap(_telegramButton);
      await tester.pumpAndSettle();

      expect(harness.opened, [Uri.parse(_telegram)]);
      expect(identical(harness.cart.state, before), isTrue);
      expect(harness.cart.state.itemCount, 1);
      expect(harness.cart.state.items.single.offering.price, 25);
      expect(harness.routes, ['/providers/company-a']);
      expect(find.text('Booking page'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('only the saved channel is offered', (tester) async {
      _setViewport(tester);
      final harness = _Harness();
      await tester.pumpWidget(
        harness.build(_provider(messengerUrl: _messenger)),
      );
      await tester.pumpAndSettle();

      expect(_messengerButton, findsOneWidget);
      expect(_telegramButton, findsNothing);
    });

    for (final (label, provider) in [
      ('no links', _provider()),
      ('blank links', _provider(telegramUrl: ' ', messengerUrl: '')),
      (
        'malformed links',
        _provider(
          telegramUrl: 'https://t.me.example.com/company_a',
          messengerUrl: 'javascript:alert(1)',
        ),
      ),
      (
        'an unverified provider',
        _provider(telegramUrl: _telegram, isVerified: false),
      ),
      (
        'a suspended provider',
        _provider(telegramUrl: _telegram, status: 'suspended'),
      ),
    ]) {
      testWidgets('$label shows no contact action', (tester) async {
        _setViewport(tester);
        final harness = _Harness();
        await tester.pumpWidget(harness.build(provider));
        await tester.pumpAndSettle();

        expect(find.text('Contact links'), findsNothing);
        expect(_telegramButton, findsNothing);
        expect(_messengerButton, findsNothing);
        expect(harness.opened, isEmpty);
      });
    }

    testWidgets('a link the device cannot open shows an error',
        (tester) async {
      _setViewport(tester);
      final harness = _Harness()..launchResult = false;
      await tester.pumpWidget(harness.build(_provider(telegramUrl: _telegram)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(_telegramButton);
      await tester.tap(_telegramButton);
      await tester.pumpAndSettle();

      expect(harness.opened, [Uri.parse(_telegram)]);
      expect(
        find.text('Couldn’t open Telegram. Check that Telegram or a web '
            'browser is installed, then try again.'),
        findsOneWidget,
      );
      expect(harness.cart.state.itemCount, 1);
    });

    for (final locale in [const Locale('en'), const Locale('km')]) {
      for (final width in [320.0, 360.0]) {
        testWidgets(
            'contact actions fit at ${width.toInt()}dp, 130% text, '
            '${locale.languageCode}', (tester) async {
          _setViewport(tester, width: width);
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final harness = _Harness();
          await tester.pumpWidget(harness.build(
            _provider(telegramUrl: _telegram, messengerUrl: _messenger),
            locale: locale,
          ));
          await tester.pumpAndSettle();

          await tester.ensureVisible(_messengerButton);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final button in [_telegramButton, _messengerButton]) {
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          }
        });
      }
    }
  });
}
