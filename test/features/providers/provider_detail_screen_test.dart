import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/screens/provider_detail_screen.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/providers/widgets/provider_type_badge.dart';
import 'package:service_pilot/l10n/app_localizations.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';

class _DeferredProfileService extends ProviderService {
  final response = Completer<ProviderModel?>();

  @override
  Future<ProviderModel?> getProviderById(String providerId) => response.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildProviderDetailTestApp({
    required String providerId,
    ProviderModel? initialProvider,
    IProviderService? customService,
    void Function(String route)? onNavigated,
  }) {
    final router = GoRouter(
      initialLocation: '/providers/$providerId',
      routes: [
        GoRoute(
          path: '/providers/:providerId',
          builder: (_, state) {
            final pId = state.pathParameters['providerId'] ?? '';
            final provider = state.extra as ProviderModel? ?? initialProvider;
            return ProviderDetailScreen(
              providerId: pId,
              initialProvider: provider,
            );
          },
        ),
        GoRoute(
          path: '/providers/:providerId/book',
          builder: (_, state) {
            final pId = state.pathParameters['providerId'] ?? '';
            onNavigated?.call('/providers/$pId/book');
            return Scaffold(
              body: Center(child: Text('Booking Page for $pId')),
            );
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        if (customService != null)
          providerServiceProvider.overrideWithValue(customService),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  void setupViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('SCRUM-54 / US-11: ProviderDetailScreen Acceptance Criteria Tests', () {
    testWidgets(
        'AC #1: Displays provider name, description, bio, and service specialties',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(
        buildProviderDetailTestApp(providerId: 'prov-dara-ac'),
      );
      await tester.pumpAndSettle();

      // Name & Tagline
      expect(find.text('Dara Chhum'), findsWidgets);
      expect(
        find.text('Certified Inverter & Split AC Specialist'),
        findsOneWidget,
      );

      // Bio text in About section
      expect(
        find.textContaining('Certified HVAC technician with over 7 years'),
        findsOneWidget,
      );

      // Service specialties
      expect(find.text('Inverter AC Diagnostics'), findsOneWidget);
      expect(find.text('Chemical Coil Wash'), findsOneWidget);
      expect(find.text('Compressor Replacement'), findsOneWidget);
    });

    testWidgets(
        'AC #2: Displays provider service coverage area (e.g., Toul Kork, Sen Sok, Chamkarmon)',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(
        buildProviderDetailTestApp(providerId: 'prov-dara-ac'),
      );
      await tester.pumpAndSettle();

      // Section title
      final coverageSection = find.text('Service areas');
      await tester.scrollUntilVisible(
        coverageSection,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(coverageSection, findsOneWidget);

      // Coverage districts
      expect(find.text('Toul Kork'), findsOneWidget);
      expect(find.text('Sen Sok'), findsOneWidget);
      expect(find.text('Daun Penh'), findsOneWidget);
    });

    testWidgets(
        'AC #3: Profile identifies whether the provider is an independent technician or repair company',
        (tester) async {
      setupViewport(tester);

      // 1. Independent Technician
      await tester.pumpWidget(
        buildProviderDetailTestApp(providerId: 'prov-dara-ac'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProviderTypeBadge), findsOneWidget);
      expect(find.text('Independent technician'), findsOneWidget);

      // 2. Repair Company
      await tester.pumpWidget(
        buildProviderDetailTestApp(providerId: 'prov-khmer-cool'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Repair company'), findsOneWidget);
      expect(
        find.text('Khmer Cool Aircon & Home Care Co., Ltd.'),
        findsWidgets,
      );
    });

    testWidgets('An available provider can open its booking preview',
        (tester) async {
      setupViewport(tester);
      String? navigatedRoute;

      await tester.pumpWidget(
        buildProviderDetailTestApp(
          providerId: 'prov-dara-ac',
          onNavigated: (route) => navigatedRoute = route,
        ),
      );
      await tester.pumpAndSettle();

      // Available indicator
      expect(
        find.text('Available'),
        findsOneWidget,
      );

      final bookButtonFinder =
          find.widgetWithText(SpPrimaryButton, 'Continue to booking');
      expect(bookButtonFinder, findsOneWidget);

      // Verify button is enabled
      final buttonWidget = tester.widget<SpPrimaryButton>(bookButtonFinder);
      expect(buttonWidget.enabled, isTrue);

      // Tap the button
      await tester.tap(bookButtonFinder);
      await tester.pumpAndSettle();

      // Verify navigation to /providers/:providerId/book
      expect(navigatedRoute, '/providers/prov-dara-ac/book');
      expect(find.text('Booking Page for prov-dara-ac'), findsOneWidget);
    });

    testWidgets(
        'AC #5: Unavailable providers cannot receive new booking requests (Book button disabled)',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(
        buildProviderDetailTestApp(providerId: 'prov-sopheap-plumbing'),
      );
      await tester.pumpAndSettle();

      // Verify unavailable status banner is displayed
      expect(
        find.text('Currently unavailable'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Fully booked for today'),
        findsOneWidget,
      );

      // Verify button is disabled
      final bookButtonFinder =
          find.widgetWithText(SpPrimaryButton, 'Continue to booking');
      expect(bookButtonFinder, findsOneWidget);

      final buttonWidget = tester.widget<SpPrimaryButton>(bookButtonFinder);
      expect(buttonWidget.enabled, isFalse);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('shows Not Found state when provider does not exist',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(
        buildProviderDetailTestApp(providerId: 'non-existent-provider'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Provider not found'), findsOneWidget);
      expect(find.text('Back to providers'), findsOneWidget);
    });

    for (final withInitial in [false, true]) {
      testWidgets('loading a provider with initial profile $withInitial',
          (tester) async {
        final service = _DeferredProfileService();
        await tester.pumpWidget(buildProviderDetailTestApp(
          providerId: 'test-provider',
          initialProvider: withInitial
              ? const ProviderModel(id: 'test-provider', name: 'Directory copy')
              : null,
          customService: service,
        ));
        expect(find.byType(CircularProgressIndicator),
            withInitial ? findsNothing : findsOneWidget);
        expect(find.text('Directory copy'),
            withInitial ? findsOneWidget : findsNothing);
        service.response.complete(
          const ProviderModel(id: 'test-provider', name: 'Updated profile'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Updated profile'), findsOneWidget);
      });
    }

    testWidgets('profile error without initial data offers a retry',
        (tester) async {
      final service = _DeferredProfileService();
      await tester.pumpWidget(buildProviderDetailTestApp(
        providerId: 'test-provider',
        customService: service,
      ));
      service.response.completeError(StateError('internal failure'));
      await tester.pumpAndSettle();
      expect(
          find.text('Couldn’t load this provider’s profile.'), findsOneWidget);
      expect(find.textContaining('internal failure'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
