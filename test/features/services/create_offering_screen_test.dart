import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/providers/category_provider.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/features/services/screens/create_offering_screen.dart';
import 'package:service_pilot/features/services/services/category_service.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

class _MockAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthStateAuthenticated(
        UserModel(
          id: 'prov-tech-1',
          fullName: 'Tech Lead',
          email: 'tech@test.com',
          phoneNumber: '+85512345678',
          role: AppRole.independentProvider,
          status: 'active',
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testCategories = [
    const CategoryModel(
      id: 'cat-ac',
      name: 'Air Conditioner Repair & Care',
      description: 'AC Care',
      iconName: 'ac_unit',
      providerCount: 5,
    ),
  ];

  Widget buildTestApp({
    IOfferingService? customOfferingService,
    ICategoryService? customCategoryService,
  }) {
    return ProviderScope(
      overrides: [
        if (customOfferingService != null)
          offeringServiceProvider.overrideWithValue(customOfferingService),
        if (customCategoryService != null)
          categoryServiceProvider.overrideWithValue(customCategoryService),
        authProvider.overrideWith(() => _MockAuthNotifier()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CreateOfferingScreen(initialCategoryId: 'cat-ac'),
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

  group('SCRUM-77 / SCRUM-119: CreateOfferingScreen Listing Form Tests', () {
    testWidgets(
        'Renders listing form with default Quote-Required mode and notice',
        (tester) async {
      setupViewport(tester);
      final categoryService =
          CategoryService(initialCategories: testCategories);

      await tester.pumpWidget(buildTestApp(
        customCategoryService: categoryService,
      ));
      await tester.pumpAndSettle();

      // Form heading
      expect(find.text('New Service Offering'), findsOneWidget);
      expect(find.byKey(const Key('offering_title_field')), findsOneWidget);
      expect(
          find.byKey(const Key('offering_description_field')), findsOneWidget);

      // Quote mode radio is selected by default
      final radioGroup = tester.widget<RadioGroup<OfferingPricingMode>>(
        find.byType(RadioGroup<OfferingPricingMode>),
      );
      expect(radioGroup.groupValue, OfferingPricingMode.quoteRequired);

      // Informational notice is visible
      expect(find.byKey(const Key('quote_mode_notice')), findsOneWidget);

      // Fixed price field is not visible in quote required mode
      expect(find.byKey(const Key('offering_price_field')), findsNothing);
    });

    testWidgets(
        'Switching to Fixed Price mode displays standard price and unit fields',
        (tester) async {
      setupViewport(tester);
      final categoryService =
          CategoryService(initialCategories: testCategories);

      await tester.pumpWidget(buildTestApp(
        customCategoryService: categoryService,
      ));
      await tester.pumpAndSettle();

      // Tap Fixed Price radio
      await tester.tap(find.byKey(const Key('pricing_mode_fixed')));
      await tester.pumpAndSettle();

      // Price field appears
      expect(find.byKey(const Key('offering_price_field')), findsOneWidget);
      expect(find.byKey(const Key('offering_unit_field')), findsOneWidget);

      // Quote notice disappears
      expect(find.byKey(const Key('quote_mode_notice')), findsNothing);
    });

    testWidgets(
        'Submitting a Quote-Required offering saves with quoteRequired mode and price null',
        (tester) async {
      setupViewport(tester);
      final categoryService =
          CategoryService(initialCategories: testCategories);
      final offeringService = OfferingService(initialOfferings: []);

      await tester.pumpWidget(buildTestApp(
        customCategoryService: categoryService,
        customOfferingService: offeringService,
      ));
      await tester.pumpAndSettle();

      // Enter title and description
      await tester.enterText(
        find.byKey(const Key('offering_title_field')),
        'Inverter PCB Board Diagnostics',
      );
      await tester.enterText(
        find.byKey(const Key('offering_description_field')),
        'Complete circuit board inspection and micro-soldering diagnostics.',
      );
      await tester.pumpAndSettle();

      // Ensure Quote Required mode is chosen
      await tester.tap(find.byKey(const Key('pricing_mode_quote_required')));
      await tester.pumpAndSettle();

      // Tap Publish button
      await tester.tap(find.byKey(const Key('publish_offering_button')));
      await tester.pumpAndSettle();

      // Verify offering was saved in offeringService
      final offerings = await offeringService.getOfferings();
      expect(offerings.length, 1);
      final saved = offerings.first;
      expect(saved.title, 'Inverter PCB Board Diagnostics');
      expect(saved.isQuoteRequired, isTrue);
      expect(saved.price, isNull);
      expect(saved.canAddToCart, isFalse);
    });
  });
}
