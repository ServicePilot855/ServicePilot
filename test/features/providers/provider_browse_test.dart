import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/router/app_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/bookings/screens/booking_tracking_screen.dart';
import 'package:service_pilot/features/bookings/screens/create_booking_screen.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/screens/provider_detail_screen.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/services/screens/categories_screen.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/main.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/status_badge.dart';

class _SignedInUser extends AuthNotifier {
  _SignedInUser(this.role);

  final AppRole role;

  @override
  AuthState build() => AuthStateAuthenticated(
        UserModel(
          id: 'customer',
          fullName: 'Test Customer',
          email: 'customer@example.test',
          phoneNumber: '123',
          role: role,
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
    Locale? previewLocale,
    AppRole role = AppRole.homeowner,
  }) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.defaultRouteNameTestValue = path;
    addTearDown(dispatcher.clearDefaultRouteNameTestValue);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        if (signedIn) authProvider.overrideWith(() => _SignedInUser(role)),
        if (service != null) providerServiceProvider.overrideWithValue(service),
      ],
      child: previewLocale == null
          ? const ServicePilotApp()
          : Consumer(
              builder: (_, ref, __) => MaterialApp.router(
                locale: previewLocale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: AppTheme.lightTheme,
                routerConfig: ref.watch(appRouterProvider),
              ),
            ),
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
    expect(find.text('Repair company'), findsOneWidget);
    expect(find.text('Toul Kork'), findsOneWidget);
    expect(find.text('Test Technician'), findsOneWidget);
    expect(find.text('Independent technician'), findsOneWidget);
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
    expect(find.text('Provider profile'), findsOneWidget);
    expect(find.text('Trust & Safety Guarantee'), findsNothing);
    expect(find.text('Verified Provider'), findsNothing);
    await tester.tap(find.text('Continue to booking'));
    await tester.pumpAndSettle();
    // US-12 (SCRUM-43): the booking request form for this provider.
    final bookingForm = find.byType(CreateBookingScreen);
    expect(bookingForm, findsOneWidget);
    expect(tester.widget<CreateBookingScreen>(bookingForm).providerId,
        'company-1');
    expect(
      GoRouterState.of(tester.element(bookingForm)).uri.path,
      '/providers/company-1/book',
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(ProviderDetailScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Test Technician'), findsOneWidget);
  });

  testWidgets('a failed directory request can be retried', (tester) async {
    final service = _FlakyProviderService();
    await open(tester, '/categories/cat-plumbing/providers', service: service);

    expect(find.text('Couldn’t load providers.'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pump();
      final retry = tester.getSemantics(find.bySemanticsLabel('Try again'));
      expect(retry.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    } finally {
      semantics.dispose();
    }
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

  testWidgets('Back from a directly opened profile goes to categories',
      (tester) async {
    await open(tester, '/providers/prov-dara-ac');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoriesScreen), findsOneWidget);
  });

  testWidgets('Home categories and pending booking keep their route targets',
      (tester) async {
    await open(tester, '/home/customer');
    await tester.tap(find.byKey(const Key('home_category_cat-ac')).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Service providers'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final booking = find.byKey(const Key('home_booking_bk-pending-01'));
    await tester.ensureVisible(booking);
    await tester.pumpAndSettle();
    final status = find.descendant(of: booking, matching: find.byType(StatusBadge));
    expect(find.descendant(of: status, matching: find.text('Pending')), findsOneWidget);
    final badge = tester.widget<Container>(
      find.descendant(of: status, matching: find.byType(Container)),
    );
    expect((badge.decoration! as BoxDecoration).color, AppTheme.accentSoft);
    await tester.tap(booking);
    await tester.pumpAndSettle();
    expect(find.byType(BookingTrackingScreen), findsOneWidget);
  });

  testWidgets('Technician home still uses the shared page background', (tester) async {
    await open(tester, '/home/technician', role: AppRole.independentProvider);
    expect(
      find.text('Your job board and earnings dashboard are coming soon.'),
      findsOneWidget,
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppTheme.background,
    );
  });

  test('discovery text, CTA and control border meet contrast thresholds', () {
    double contrast(Color dark, Color light) =>
        (light.computeLuminance() + 0.05) / (dark.computeLuminance() + 0.05);

    for (final surface in [
      AppTheme.surface,
      AppTheme.browseBackground,
      AppTheme.browseFill,
    ]) {
      expect(contrast(AppTheme.browseInk, surface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppTheme.browseSecondary, surface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppTheme.primary, surface), greaterThanOrEqualTo(4.5));
    }
    expect(contrast(AppTheme.browseControlBorder, AppTheme.surface),
        greaterThanOrEqualTo(3));
    expect(contrast(AppTheme.browseControlBorder, AppTheme.browseBackground),
        greaterThanOrEqualTo(3));
  });

  final ratingCases = [
    ('zero reviews', {'rating': 5.0, 'reviewCount': 0}, 'No reviews yet'),
    ('missing rating', {'reviewCount': 3}, 'Rating unavailable'),
    ('missing count', {'rating': 5.0}, 'Rating unavailable'),
    ('invalid rating', {'rating': 6.0, 'reviewCount': 3}, 'Rating unavailable'),
    (
      'recorded perfect rating',
      {'rating': 5.0, 'reviewCount': 1},
      '5.0 · 1 review'
    ),
    ('recorded rating', {'rating': 4.8, 'reviewCount': 24}, '4.8 · 24 reviews'),
  ];
  for (final (name, fields, label) in ratingCases) {
    testWidgets('$name displays consistently in list and detail',
        (tester) async {
      final provider = ProviderModel.fromMap({
        'name': 'Test Provider',
        'categoryIds': ['cat-plumbing'],
        ...fields,
      }, 'test-provider');
      final service = ProviderService(initialProviders: [provider]);
      await open(tester, '/categories/cat-plumbing/providers',
          service: service);

      void expectRating() {
        expect(find.text(label), findsOneWidget);
        expect(
          find.byIcon(Icons.star_rounded),
          label.contains(' · ') ? findsOneWidget : findsNothing,
        );
      }

      expectRating();
      await tester.tap(find.text('Test Provider'));
      await tester.pumpAndSettle();
      expectRating();
    });
  }

  for (final language in ['en', 'km']) {
    for (final width in [320.0, 360.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
            'discovery preview in $language at $width dp and $scale scale',
            (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 720);
          tester.view.padding = const FakeViewPadding(bottom: 24);
          final dispatcher = tester.binding.platformDispatcher;
          dispatcher.textScaleFactorTestValue = scale;
          addTearDown(() {
            dispatcher.clearTextScaleFactorTestValue();
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            tester.view.resetViewInsets();
            tester.view.resetPadding();
          });
          final khmer = language == 'km';
          const name =
              'ក្រុមហ៊ុនជួសជុលផ្ទះភ្នំពេញ · Phnom Penh Repair Specialists';
          const service = [
            ProviderModel(
              id: 'preview-company',
              name: 'Company owner',
              businessName: name,
              type: ProviderType.company,
              categoryIds: ['cat-plumbing'],
              coverageAreas: ['ខណ្ឌទួលគោក', 'ខណ្ឌសែនសុខ', 'Chamkarmon'],
              rating: 4.8,
              reviewCount: 24,
              specialties: ['ជួសជុលបំពង់ទឹក និងបំពង់បង្ហូរទឹក'],
              bio: 'ជាងជួសជុលនៅភ្នំពេញ។ Repairs and maintenance in Phnom Penh.',
            ),
          ];
          await open(
            tester,
            '/home/customer',
            previewLocale: Locale(language),
            service: ProviderService(initialProviders: service),
          );
          final browse = find.text(khmer ? 'មើលសេវាកម្ម' : 'Browse services');
          expect(browse.hitTestable(), findsOneWidget);
          final categoryHeading =
              find.text(khmer ? 'ប្រភេទសេវាកម្ម' : 'Service categories');
          expect(
            tester.getBottomLeft(categoryHeading).dy,
            lessThan(tester.getTopLeft(browse).dy),
          );
          final browseButton = find.byKey(const Key('customer_home_search_bar'));
          final browseStyle = tester.widget<TextButton>(browseButton).style!;
          expect(browseStyle.backgroundColor!.resolve({}), AppTheme.surface);
          expect(browseStyle.side!.resolve({})!.color, AppTheme.browseControlBorder);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          final focusedOutline = find.descendant(
            of: browseButton,
            matching: find.byWidgetPredicate(
              (widget) => widget is Material &&
                  widget.shape is OutlinedBorder &&
                  (widget.shape! as OutlinedBorder).side ==
                      const BorderSide(color: AppTheme.primary, width: 2),
            ),
          );
          expect(focusedOutline, findsOneWidget);
          await tester.tap(browse);
          await tester.pumpAndSettle();
          final search = find.byKey(const Key('category_search_field'));
          expect(
            find.text(khmer ? 'ស្វែងរកប្រភេទសេវា' : 'Search categories'),
            findsOneWidget,
          );

          tester.view.viewInsets = const FakeViewPadding(bottom: 250);
          await tester.enterText(search, 'Plumbing');
          await tester.pumpAndSettle();
          final searchDecorator = tester.widget<InputDecorator>(
            find.descendant(of: search, matching: find.byType(InputDecorator)),
          );
          expect(searchDecorator.isFocused, isTrue);
          expect(searchDecorator.decoration.fillColor, AppTheme.surface);
          expect(searchDecorator.decoration.enabledBorder!.borderSide.color,
              AppTheme.browseControlBorder);
          expect(searchDecorator.decoration.focusedBorder!.borderSide,
              const BorderSide(color: AppTheme.primary, width: 2));
          final category = find.text('Plumbing & Drainage');
          expect(category.hitTestable(), findsOneWidget);
          tester.view.resetViewInsets();
          await tester.tap(category);
          await tester.pumpAndSettle();

          expect(
            find.text(khmer ? 'អ្នកផ្តល់សេវា' : 'Service providers'),
            findsOneWidget,
          );
          expect(
            find.text(khmer ? 'ក្រុមហ៊ុនជួសជុល' : 'Repair company'),
            findsOneWidget,
          );
          expect(find.textContaining(khmer ? 'ការវាយតម្លៃ' : '24 reviews'),
              findsOneWidget);
          final card = find
              .ancestor(
                of: find.text(name),
                matching: find.byType(MergeSemantics),
              )
              .first;
          final semantics = tester.ensureSemantics();
          try {
            await tester.pump();
            final node = tester.getSemantics(card);
            expect(node.label, contains(name));
            expect(node.label, contains(khmer ? 'ពិន្ទុ' : '4.8 out of 5'));
            expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
          } finally {
            semantics.dispose();
          }
          expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
          await tester.tap(find.text(name));
          await tester.pumpAndSettle();

          final cta = find.text(khmer ? 'បន្តទៅការកក់' : 'Continue to booking');
          expect(cta.hitTestable(), findsOneWidget);
          final areasHeading = find.text(khmer ? 'តំបន់ផ្តល់សេវា' : 'Service areas');
          final summaryCard = find.ancestor(
            of: areasHeading,
            matching: find.byWidgetPredicate(
              (widget) => widget is DecoratedBox &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration as BoxDecoration).color == AppTheme.surface &&
                  (widget.decoration as BoxDecoration).borderRadius ==
                      BorderRadius.circular(AppTheme.radiusCard),
            ),
          );
          expect(
            find.descendant(of: summaryCard, matching: find.text(name)),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: summaryCard,
              matching: find.text(khmer ? 'អាចទទួលការកក់' : 'Available'),
            ),
            findsOneWidget,
          );
          expect(tester.renderObject<RenderParagraph>(cta).didExceedMaxLines,
              isFalse);
          final bookingButton = find.ancestor(
            of: cta,
            matching: find.byType(SpPrimaryButton),
          );
          expect(tester.getSize(bookingButton).height, greaterThanOrEqualTo(48));
          expect(tester.getBottomLeft(bookingButton).dy, lessThanOrEqualTo(696));
          await tester.scrollUntilVisible(
            find.text(khmer ? 'អំពីអ្នកផ្តល់សេវា' : 'About'),
            150,
            scrollable: find.byType(Scrollable),
          );
          expect(cta.hitTestable(), findsOneWidget);
          await tester.tap(cta);
          await tester.pumpAndSettle();
          final bookingForm = find.byType(CreateBookingScreen);
          expect(bookingForm, findsOneWidget);
          expect(GoRouterState.of(tester.element(bookingForm)).uri.path,
              '/providers/preview-company/book');
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
