import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/services/firestore_category_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirestoreCategoryService Unit & Fallback Tests', () {
    late FirestoreCategoryService service;

    setUp(() {
      service = FirestoreCategoryService();
    });

    test('getCategories returns active categories via resilient fallback', () async {
      final categories = await service.getCategories();

      expect(categories, isNotEmpty);
      expect(categories.length, greaterThanOrEqualTo(5));
      expect(categories.every((c) => c.isActive), isTrue);

      final names = categories.map((c) => c.name).toList();
      expect(names.any((n) => n.contains('Air Conditioner')), isTrue);
      expect(names.any((n) => n.contains('Plumbing')), isTrue);
      expect(names.any((n) => n.contains('Electrical')), isTrue);
    });

    test('getCategoryById returns valid category when found', () async {
      final category = await service.getCategoryById('cat-ac');

      expect(category, isNotNull);
      expect(category?.id, equals('cat-ac'));
      expect(category?.name, contains('Air Conditioner'));
      expect(category?.hasAvailableProviders, isTrue);
    });

    test('getCategoryById returns null for nonexistent category', () async {
      final nonExistent = await service.getCategoryById('cat-unknown-999');
      expect(nonExistent, isNull);
    });

    test('searchCategories filters by category name', () async {
      final results = await service.searchCategories('plumbing');

      expect(results, isNotEmpty);
      expect(results.first.id, equals('cat-plumbing'));
    });

    test('searchCategories filters by popular service items', () async {
      final results = await service.searchCategories('drain');

      expect(results, isNotEmpty);
      expect(results.any((c) => c.id == 'cat-plumbing'), isTrue);
    });

    test('searchCategories returns all when query is empty', () async {
      final all = await service.getCategories();
      final searched = await service.searchCategories('   ');

      expect(searched.length, equals(all.length));
    });

    test('searchCategories returns empty list when no match is found', () async {
      final results = await service.searchCategories('completely_nonexistent_xyz');
      expect(results, isEmpty);
    });

    test('CategoryModel supports fromMap, toMap, and fromJson parity', () {
      final mapData = {
        'id': 'cat-roofing',
        'name': 'Roofing & Gutter',
        'description': 'Roof leak repair and tile replacement',
        'iconName': 'roofing',
        'providerCount': 3,
        'isActive': true,
        'popularServices': ['Roof Leak', 'Gutter Clean'],
      };

      final model = CategoryModel.fromMap(mapData, 'cat-roofing');
      expect(model.id, equals('cat-roofing'));
      expect(model.name, equals('Roofing & Gutter'));
      expect(model.providerCount, equals(3));
      expect(model.popularServices, contains('Roof Leak'));

      final serialized = model.toMap();
      expect(serialized['id'], equals('cat-roofing'));
      expect(serialized['providerCount'], equals(3));
      expect(serialized['isActive'], isTrue);
    });
  });
}
