import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:service_pilot/features/services/models/category_model.dart';

void main() {
  group('SCRUM-41 / US-09: CategoryModel Unit Tests', () {
    test('supports JSON serialization and deserialization', () {
      const category = CategoryModel(
        id: 'cat-test',
        name: 'Test Category',
        description: 'Testing description',
        iconName: 'ac_unit',
        providerCount: 5,
        isActive: true,
        popularServices: ['Sub 1', 'Sub 2'],
      );

      final json = category.toJson();
      expect(json['id'], equals('cat-test'));
      expect(json['name'], equals('Test Category'));
      expect(json['description'], equals('Testing description'));
      expect(json['providerCount'], equals(5));
      expect(json['isActive'], isTrue);
      expect(json['popularServices'], equals(['Sub 1', 'Sub 2']));

      final fromJson = CategoryModel.fromJson(json);
      expect(fromJson.id, equals(category.id));
      expect(fromJson.name, equals(category.name));
      expect(fromJson.description, equals(category.description));
      expect(fromJson.providerCount, equals(5));
      expect(fromJson.hasAvailableProviders, isTrue);
    });

    test('hasAvailableProviders returns false when providerCount is zero', () {
      const emptyCat = CategoryModel(
        id: 'cat-empty',
        name: 'Empty Category',
        description: 'No providers yet',
        iconName: 'tools',
        providerCount: 0,
      );

      expect(emptyCat.hasAvailableProviders, isFalse);
    });

    test('iconData maps known icon names to Material icons', () {
      const acCat = CategoryModel(
        id: '1',
        name: 'AC',
        description: 'AC',
        iconName: 'ac_unit',
      );
      expect(acCat.iconData, equals(Icons.ac_unit_rounded));

      const plumbingCat = CategoryModel(
        id: '2',
        name: 'Plumbing',
        description: 'Plumbing',
        iconName: 'plumbing',
      );
      expect(plumbingCat.iconData, equals(Icons.plumbing_rounded));

      const unknownCat = CategoryModel(
        id: '3',
        name: 'Other',
        description: 'Other',
        iconName: 'unknown_icon',
      );
      expect(unknownCat.iconData, equals(Icons.build_rounded));
    });

    test('copyWith updates properties properly', () {
      const original = CategoryModel(
        id: 'cat-1',
        name: 'Orig',
        description: 'Orig Desc',
        iconName: 'bolt',
        providerCount: 2,
      );

      final updated = original.copyWith(name: 'Updated Name', providerCount: 10);
      expect(updated.id, equals('cat-1'));
      expect(updated.name, equals('Updated Name'));
      expect(updated.providerCount, equals(10));
      expect(updated.description, equals('Orig Desc'));
    });
  });
}
