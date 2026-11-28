import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/screens/provider_detail_screen.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/providers/category_provider.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/features/services/screens/create_offering_screen.dart';
import 'package:service_pilot/features/services/services/category_service.dart';
import 'package:service_pilot/features/services/services/offering_service.dart';
import 'package:service_pilot/features/services/widgets/provider_offering_list.dart';
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
    List<ProviderModel>? providers,
    String? categoryId = 'cat-ac',
    String? providerId,
    String initialLocation = '/offerings/create',
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/offerings/create',
          builder: (_, __) => CreateOfferingScreen(
            initialCategoryId: categoryId,
            initialProviderId: providerId,
          ),
        ),
        GoRoute(
          path: '/offerings/:offeringId/edit',
          builder: (_, state) => EditOfferingScreen(
              offeringId: state.pathParameters['offeringId']!),
        ),
        GoRoute(
          path: '/home/:role',
          builder: (_, __) => Scaffold(
            body: ListView(
              children: [
                const Text('Provider home'),
                if (initialLocation == '/home/technician')
                  const ProviderOfferingList(
                    providerId: 'prov-tech-1',
                    providerName: 'Tech Lead',
                  ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/providers/:id',
          builder: (_, state) =>
              ProviderDetailScreen(providerId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    return ProviderScope(
      overrides: [
        if (providers != null)
          providerServiceProvider.overrideWithValue(
            ProviderService(initialProviders: providers),
          ),
        if (customOfferingService != null)
          offeringServiceProvider.overrideWithValue(customOfferingService),
        if (customCategoryService != null)
          categoryServiceProvider.overrideWithValue(customCategoryService),
        authProvider.overrideWith(() => _MockAuthNotifier(mockUser)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  void setupViewport(WidgetTester tester, {Size size = const Size(800, 1600)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> enterFixedOffering(
    WidgetTester tester, {
    String price = '25.49',
    String title = 'Split Unit Wash',
    bool selectCategory = false,
    bool showKeyboard = false,
  }) async {
    if (selectCategory) {
      await tester.tap(find.byKey(const Key('offering_category_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testCategories.first.name).last);
      await tester.pumpAndSettle();
    }
    await tester.enterText(
      find.byKey(const Key('offering_title_field')),
      title,
    );
    await tester.enterText(
      find.byKey(const Key('offering_description_field')),
      'Deep cleaning and drain inspection.',
    );
    final fixedMode = find.byKey(const Key('pricing_mode_fixed'));
    await tester.ensureVisible(fixedMode);
    await tester.tap(fixedMode);
    await tester.pumpAndSettle();
    final priceField = find.byKey(const Key('offering_price_field'));
    await tester.ensureVisible(priceField);
    await tester.enterText(priceField, price);
    if (showKeyboard) {
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
    } else {
      await tester.testTextInput.receiveAction(TextInputAction.done);
    }
    await tester.pumpAndSettle();
    final publish = find.byKey(const Key('publish_offering_button'));
    await tester.ensureVisible(publish);
    await tester.tap(publish);
    await tester.pumpAndSettle();
  }

  const technician = ProviderModel(id: 'prov-tech-1', name: 'Tech Lead');
  const company = ProviderModel(
    id: 'prov-company-1',
    name: 'Company Admin',
    businessName: 'AirCare',
    type: ProviderType.company,
  );
  const companyAdmin = UserModel(
    id: 'prov-company-1',
    fullName: 'Company Admin',
    email: 'company-admin@example.test',
    phoneNumber: '+85511223344',
    role: AppRole.company,
    status: 'active',
    companyId: 'prov-company-1',
  );
  const existingListing = OfferingModel(
    id: 'existing',
    providerId: 'prov-tech-1',
    providerName: 'Tech Lead',
    categoryId: 'cat-ac',
    title: 'Split Unit Wash',
    description: 'Deep cleaning and drain inspection.',
    pricingMode: OfferingPricingMode.fixed,
    price: 25.49,
  );

  testWidgets('opens a prefilled dashboard listing and refreshes its profile',
      (tester) async {
    setupViewport(tester, size: const Size(360, 900));
    final service = OfferingService(initialOfferings: [existingListing]);
    await tester.pumpWidget(buildTestApp(
      initialLocation: '/home/technician',
      customCategoryService: CategoryService(initialCategories: testCategories),
      customOfferingService: service,
      providers: [technician, company],
      textScale: 1.3,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit_offering_existing')));
    await tester.pumpAndSettle();

    expect(find.text('Split Unit Wash'), findsOneWidget);
    final price = find.byKey(const Key('offering_price_field'));
    await tester.ensureVisible(price);
    expect(find.text('25.49'), findsOneWidget);
    await tester.enterText(price, '35.75');
    final save = find.byKey(const Key('save_offering_button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect((await service.getOfferings()).single.price, 35.75);
    expect(find.text(r'$35.75'), findsOneWidget);
    final router = GoRouter.of(tester.element(find.text('Provider home')));
    router.go('/providers/prov-tech-1');
    await tester.pumpAndSettle();
    expect(find.text(r'$35.75'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('another provider cannot open the edit form by its URL',
      (tester) async {
    setupViewport(tester);
    await tester.pumpWidget(buildTestApp(
      initialLocation: '/offerings/existing/edit',
      customOfferingService:
          OfferingService(initialOfferings: [existingListing]),
      mockUser: companyAdmin,
    ));
    await tester.pumpAndSettle();
    expect(
        find.text('This listing is unavailable for editing.'), findsOneWidget);
    expect(find.byKey(const Key('save_offering_button')), findsNothing);
  });

  group('SCRUM-76 fixed-price publishing', () {
    for (final (locale, width) in [
      (const Locale('en'), 320.0),
      (const Locale('km'), 360.0)
    ]) {
      testWidgets(
          'shows missing-price feedback at ${width.toInt()}dp in ${locale.languageCode}',
          (tester) async {
        setupViewport(tester, size: Size(width, 800));
        final service = OfferingService(initialOfferings: []);
        await tester.pumpWidget(buildTestApp(
          customCategoryService:
              CategoryService(initialCategories: testCategories),
          customOfferingService: service,
          providers: [technician],
          locale: locale,
          textScale: 1.3,
        ));
        await tester.pumpAndSettle();
        await enterFixedOffering(tester, price: '', showKeyboard: true);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(CreateOfferingScreen)),
        )!;
        expect(find.text(l10n.offeringPriceRequired), findsOneWidget);
        expect(await service.getOfferings(), isEmpty);
        expect(
          tester
              .getBottomLeft(find.byKey(const Key('publish_offering_button')))
              .dy,
          lessThanOrEqualTo(540),
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final provider in [technician, company]) {
      testWidgets(
          'publishes the saved price on the ${provider.type.name} profile',
          (tester) async {
        setupViewport(tester);
        final service = OfferingService(initialOfferings: []);
        await tester.pumpWidget(buildTestApp(
          customCategoryService:
              CategoryService(initialCategories: testCategories),
          customOfferingService: service,
          providers: [technician, company],
          mockUser: provider.isCompany ? companyAdmin : null,
          categoryId: null,
        ));
        await tester.pumpAndSettle();
        await enterFixedOffering(tester, selectCategory: true);

        final saved = (await service.getOfferings()).single;
        expect(saved.providerId, provider.id);
        expect(saved.providerName, provider.displayName);
        expect(saved.providerType, provider.type);
        expect(saved.categoryId, 'cat-ac');
        expect(saved.pricingMode, OfferingPricingMode.fixed);
        expect(saved.price, 25.49);
        expect(find.text('Provider home'), findsOneWidget);

        final router = GoRouter.of(tester.element(find.text('Provider home')));
        router.go('/providers/${provider.id}');
        await tester.pumpAndSettle();
        expect(find.text('Split Unit Wash'), findsOneWidget);
        expect(find.text(saved.priceDisplay), findsOneWidget);

        router.go(
            '/providers/${provider.isCompany ? technician.id : company.id}');
        await tester.pumpAndSettle();
        expect(find.text('Split Unit Wash'), findsNothing);
      });
    }

    for (final price in ['', '-1', '0', 'Infinity', 'NaN', '0.001']) {
      testWidgets('rejects invalid fixed price "$price"', (tester) async {
        setupViewport(tester);
        final service = OfferingService(initialOfferings: []);
        await tester.pumpWidget(buildTestApp(
          customCategoryService:
              CategoryService(initialCategories: testCategories),
          customOfferingService: service,
          providers: [technician],
        ));
        await tester.pumpAndSettle();
        await enterFixedOffering(tester, price: price);

        expect(await service.getOfferings(), isEmpty);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(CreateOfferingScreen)),
        )!;
        expect(
          find.text(price.isEmpty
              ? l10n.offeringPriceRequired
              : l10n.offeringPricePositive),
          findsOneWidget,
        );
      });
    }

    for (final categoryId in [null, 'inactive-category']) {
      testWidgets('rejects missing or inactive category "$categoryId"',
          (tester) async {
        setupViewport(tester);
        final service = OfferingService(initialOfferings: []);
        await tester.pumpWidget(buildTestApp(
          customCategoryService: CategoryService(initialCategories: [
            ...testCategories,
            const CategoryModel(
              id: 'inactive-category',
              name: 'Inactive category',
              description: '',
              iconName: 'build',
              providerCount: 0,
              isActive: false,
            ),
          ]),
          customOfferingService: service,
          providers: [technician],
          categoryId: categoryId,
        ));
        await tester.pumpAndSettle();
        await enterFixedOffering(tester);

        expect(await service.getOfferings(), isEmpty);
        expect(find.text('Please select a service category.'), findsOneWidget);
      });
    }

    testWidgets('rejects a route targeting another company', (tester) async {
      setupViewport(tester);
      final service = OfferingService(initialOfferings: []);
      const otherCompany = ProviderModel(
        id: 'other-company',
        name: 'Other Company',
        type: ProviderType.company,
      );
      await tester.pumpWidget(buildTestApp(
        customCategoryService:
            CategoryService(initialCategories: testCategories),
        customOfferingService: service,
        providers: [company, otherCompany],
        mockUser: companyAdmin,
        providerId: otherCompany.id,
      ));
      await tester.pumpAndSettle();
      await enterFixedOffering(tester);

      expect(await service.getOfferings(), isEmpty);
      expect(find.byType(CreateOfferingScreen), findsOneWidget);
    });
  });

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
      expect(
          find.text(
              'Only registered service providers and companies can publish offerings.'),
          findsOneWidget);
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

      expect(
          find.text(
              'Provider account must be active to publish service offerings.'),
          findsOneWidget);
    });

    testWidgets('Issue 7: Use the company name for company offering listings',
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
