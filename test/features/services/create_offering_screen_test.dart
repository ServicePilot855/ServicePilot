import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/providers/category_provider.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/features/services/screens/create_offering_screen.dart';
import 'package:service_pilot/features/services/services/category_service.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

class _MockAuthNotifier extends AuthNotifier {
  final UserModel? _mockUser;

  _MockAuthNotifier([this._mockUser]);

  @override
  AuthState build() {
    if (_mockUser != null) {
      return AuthStateAuthenticated(_mockUser!);
    }
    return const AuthStateAuthenticated(
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
    UserModel? mockUser,
  }) {
    return ProviderScope(
      overrides: [
        if (customOfferingService != null)
          offeringServiceProvider.overrideWithValue(customOfferingService),
        if (customCategoryService != null)
          categoryServiceProvider.overrideWithValue(customCategoryService),
        authProvider.overrideWith(() => _MockAuthNotifier(mockUser)),
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
        'Submitting a Quote-Required offering saves with quoteRequired mode and resolves category name',
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
      // Issue 8: resolved category name
      expect(saved.categoryName, 'Air Conditioner Repair & Care');
    });

    testWidgets(
        'Issue 2: Restrict offering creation to provider and company roles (rejects homeowner)',
        (tester) async {
      setupViewport(tester);
      final categoryService =
          CategoryService(initialCategories: testCategories);
      final offeringService = OfferingService(initialOfferings: []);

      const homeownerUser = UserModel(
        id: 'homeowner-1',
        fullName: 'John Homeowner',
        email: 'john@example.com',
        phoneNumber: '+85511223344',
        role: AppRole.homeowner,
        status: 'active',
      );

      await tester.pumpWidget(buildTestApp(
        customCategoryService: categoryService,
        customOfferingService: offeringService,
        mockUser: homeownerUser,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('offering_title_field')),
        'Unauthorized Offering Attempt',
      );
      await tester.enterText(
        find.byKey(const Key('offering_description_field')),
        'This should be blocked because user is a homeowner.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('publish_offering_button')));
      await tester.pumpAndSettle();

      // Verify no offerings were saved
      final offerings = await offeringService.getOfferings();
      expect(offerings, isEmpty);

      // Verify error notice is displayed
      expect(find.text('Only registered service providers and companies can publish offerings.'), findsOneWidget);
    });

    testWidgets(
        'Issue 1: Require an active provider before publishing an offering (rejects suspended)',
        (tester) async {
      setupViewport(tester);
      final categoryService =
          CategoryService(initialCategories: testCategories);
      final offeringService = OfferingService(initialOfferings: []);

      const suspendedTech = UserModel(
        id: 'tech-suspended-1',
        fullName: 'Suspended Tech',
        email: 'suspended@example.com',
        phoneNumber: '+85511223344',
        role: AppRole.independentProvider,
        status: 'suspended',
      );

      await tester.pumpWidget(buildTestApp(
        customCategoryService: categoryService,
        customOfferingService: offeringService,
        mockUser: suspendedTech,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('offering_title_field')),
        'Suspended Provider Service',
      );
      await tester.enterText(
        find.byKey(const Key('offering_description_field')),
        'This should be blocked because provider status is suspended.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('publish_offering_button')));
      await tester.pumpAndSettle();

      final offerings = await offeringService.getOfferings();
      expect(offerings, isEmpty);

      expect(find.text('Provider account must be active to publish service offerings.'), findsOneWidget);
    });

    testWidgets(
        'Issue 7: Use the company name for company offering listings',
        (tester) async {
      setupViewport(tester);
      final categoryService =
          CategoryService(initialCategories: testCategories);
      final offeringService = OfferingService(initialOfferings: []);

      const companyUser = UserModel(
        id: 'company-user-1',
        fullName: 'Chan Dara Admin',
        email: 'admin@aircarepro.com',
        phoneNumber: '+85511223344',
        role: AppRole.company,
        status: 'active',
        companyName: 'AirCare Pro Cambodia Co., Ltd.',
      );

      await tester.pumpWidget(buildTestApp(
        customCategoryService: categoryService,
        customOfferingService: offeringService,
        mockUser: companyUser,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('offering_title_field')),
        'Commercial HVAC Overhaul',
      );
      await tester.enterText(
        find.byKey(const Key('offering_description_field')),
        'Full industrial and commercial heating and cooling maintenance and overhaul.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('publish_offering_button')));
      await tester.pumpAndSettle();

      final offerings = await offeringService.getOfferings();
      expect(offerings.length, 1);
      final saved = offerings.first;
      expect(saved.providerName, 'AirCare Pro Cambodia Co., Ltd.');
      expect(saved.providerType, ProviderType.company);
    });
  });
}
