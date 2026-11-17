import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/services/services/category_service.dart';

void main() {
  group('SCRUM-41 / US-09: CategoryService Unit Tests', () {
    late CategoryService categoryService;

    setUp(() {
      categoryService = CategoryService();
    });

    test('getCategories returns default active categories', () async {
      final categories = await categoryService.getCategories();

      expect(categories, isNotEmpty);
      expect(categories.length, greaterThanOrEqualTo(5));

      final categoryNames = categories.map((c) => c.name).toList();
      expect(
        categoryNames.any((n) => n.contains('Air Conditioner')),
        isTrue,
      );
      expect(
        categoryNames.any((n) => n.contains('Plumbing')),
        isTrue,
      );
      expect(
        categoryNames.any((n) => n.contains('Electrical')),
        isTrue,
      );
      expect(
        categoryNames.any((n) => n.contains('Appliance')),
        isTrue,
      );
      expect(
        categoryNames.any((n) => n.contains('Cleaning')),
        isTrue,
      );
    });

    test('getCategoryById returns matching category', () async {
      final category = await categoryService.getCategoryById('cat-ac');
      expect(category, isNotNull);
      expect(category!.id, equals('cat-ac'));
      expect(category.hasAvailableProviders, isTrue);

      final nonExistent = await categoryService.getCategoryById('cat-unknown');
      expect(nonExistent, isNull);
    });

    test('searchCategories filters by category name', () async {
      final results = await categoryService.searchCategories('plumbing');
      expect(results, hasLength(1));
      expect(results.first.id, equals('cat-plumbing'));
    });

    test('searchCategories filters by popular service item', () async {
      final results = await categoryService.searchCategories('toilet');
      expect(results, isNotEmpty);
      expect(results.first.id, equals('cat-plumbing'));
    });

    test('searchCategories returns all categories when query is empty', () async {
      final all = await categoryService.getCategories();
      final searched = await categoryService.searchCategories('');
      expect(searched.length, equals(all.length));
    });

    test('searchCategories returns empty list when no matches exist', () async {
      final results = await categoryService.searchCategories('xyz-nonexistent');
      expect(results, isEmpty);
    });

    test('includes empty category for empty-state verification', () async {
      final locksmith = await categoryService.getCategoryById('cat-locksmith');
      expect(locksmith, isNotNull);
      expect(locksmith!.providerCount, equals(0));
      expect(locksmith.hasAvailableProviders, isFalse);
    });
  });
}
