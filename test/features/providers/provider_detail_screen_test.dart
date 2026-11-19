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
      final coverageSection = find.text('Service Coverage Area');
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
      expect(find.text('Independent'), findsOneWidget);

      // 2. Repair Company
      await tester.pumpWidget(
        buildProviderDetailTestApp(providerId: 'prov-khmer-cool'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Repair Company'), findsOneWidget);
      expect(
        find.text('Khmer Cool Aircon & Home Care Co., Ltd.'),
        findsWidgets,
      );
    });

    testWidgets(
        'AC #4: Customers can start a booking request directly from profile (Book Service CTA navigates)',
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
        find.textContaining('Available for Booking'),
        findsOneWidget,
      );

      // Find the Book Service button
      final bookButtonFinder =
          find.widgetWithText(SpPrimaryButton, 'Book Service');
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
        find.text('Currently Unavailable for Bookings'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Fully booked for today'),
        findsOneWidget,
      );

      // Verify button is disabled
      final bookButtonFinder =
          find.widgetWithText(SpPrimaryButton, 'Currently Unavailable');
      expect(bookButtonFinder, findsOneWidget);

      final buttonWidget = tester.widget<SpPrimaryButton>(bookButtonFinder);
      expect(buttonWidget.enabled, isFalse);
      expect(buttonWidget.onPressed, isNull);

      // Verify helper warning text
      expect(
        find.text('Provider is currently unavailable for new bookings'),
        findsOneWidget,
      );
    });

    testWidgets('shows Not Found state when provider does not exist',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(
        buildProviderDetailTestApp(providerId: 'non-existent-provider'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Provider Not Found'), findsOneWidget);
      expect(find.text('Back to Providers'), findsOneWidget);
    });
  });
}
