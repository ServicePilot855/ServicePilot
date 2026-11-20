import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/provider_directory.dart';
import 'package:service_pilot/features/providers/screens/provider_list_screen.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/providers/category_provider.dart';
import 'package:service_pilot/features/services/screens/categories_screen.dart';
import 'package:service_pilot/features/services/services/category_service.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildCategoriesTestApp({
    ICategoryService? customService,
    String? initialLocation,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation ?? '/categories',
      routes: [
        GoRoute(
          path: '/categories',
          builder: (_, __) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/categories/:categoryId/providers',
          builder: (_, state) {
            final categoryId = state.pathParameters['categoryId'] ?? '';
            final category = state.extra as CategoryModel?;
            return ProviderListScreen(
              categoryId: categoryId,
              category: category,
            );
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        providerDirectoryProvider.overrideWithValue(
          ProviderDirectory((_, __) async => {'providers': []}),
        ),
        if (customService != null)
          categoryServiceProvider.overrideWithValue(customService),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  group('SCRUM-41 / US-09: CategoriesScreen Widget Tests', () {
    testWidgets('renders category list with titles and descriptions',
        (tester) async {
      await tester.pumpWidget(buildCategoriesTestApp());
      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Repair & Maintenance'), findsOneWidget);
      expect(find.byKey(const Key('category_search_field')), findsOneWidget);

      // Verify default categories from US-09
      expect(find.text('Air Conditioner Repair & Care'), findsOneWidget);
      expect(find.text('Plumbing & Drainage'), findsOneWidget);

      final electricalFinder = find.text('Electrical & Wiring');
      await tester.scrollUntilVisible(
        electricalFinder,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(electricalFinder, findsOneWidget);
    });

    testWidgets('search field filters categories dynamically', (tester) async {
      await tester.pumpWidget(buildCategoriesTestApp());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('category_search_field'));
      await tester.enterText(searchField, 'plumbing');
      await tester.pumpAndSettle();

      // Only plumbing should be visible
      expect(find.text('Plumbing & Drainage'), findsOneWidget);
      expect(find.text('Air Conditioner Repair & Care'), findsNothing);
      expect(find.text('Electrical & Wiring'), findsNothing);
    });

    testWidgets('empty search displays friendly empty state and clear button',
        (tester) async {
      await tester.pumpWidget(buildCategoriesTestApp());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('category_search_field'));
      await tester.enterText(searchField, 'nonexistent category query');
      await tester.pumpAndSettle();

      expect(find.text('No Categories Found'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      // Tapping clear restores all categories
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      expect(find.text('Air Conditioner Repair & Care'), findsOneWidget);
    });

    testWidgets(
        'selecting a category opens its named provider list',
        (tester) async {
      await tester.pumpWidget(buildCategoriesTestApp());
      await tester.pumpAndSettle();

      // Tap AC Repair card
      final acCard = find.byKey(const Key('category_card_cat-ac'));
      expect(acCard, findsOneWidget);
      await tester.tap(acCard);
      await tester.pumpAndSettle();

      // Should navigate to ProviderListScreen
      expect(find.byType(ProviderListScreen), findsOneWidget);
      expect(find.text('Air Conditioner Repair & Care'), findsOneWidget);
    });

    testWidgets(
        'selecting a category with a zero fixture count still opens the directory',
        (tester) async {
      await tester.pumpWidget(buildCategoriesTestApp());
      await tester.pumpAndSettle();

      // Scroll down to find the locksmith category (providerCount = 0)
      final locksmithCard = find.byKey(const Key('category_card_cat-locksmith'));
      await tester.scrollUntilVisible(
        locksmithCard,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(locksmithCard, findsOneWidget);
      await tester.tap(locksmithCard);
      await tester.pumpAndSettle();

      expect(find.byType(ProviderListScreen), findsOneWidget);
      expect(find.text('No providers are available for this category yet.'), findsOneWidget);
    });
  });
}
