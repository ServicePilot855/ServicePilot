import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/firebase/firebase_init.dart';

enum ProviderType { independent, company }

class ProviderSummary {
  const ProviderSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.serviceArea,
  });

  final String id;
  final String name;
  final ProviderType type;
  final String serviceArea;

  static ProviderSummary? fromDirectoryRow(Map<String, dynamic> row) {
    if (row['providerStatus'] != 'ACTIVE') return null;
    final type = switch (row['providerType']) {
      'INDEPENDENT' => ProviderType.independent,
      'COMPANY' => ProviderType.company,
      _ => null,
    };
    final id = row['uid'] as String?;
    final name = (row['providerName'] as String?)?.trim();
    final area = (row['serviceArea'] as String?)?.trim();
    if (type == null ||
        id == null ||
        id.isEmpty ||
        name == null ||
        name.isEmpty ||
        area == null ||
        area.isEmpty) {
      return null;
    }
    return ProviderSummary(id: id, name: name, type: type, serviceArea: area);
  }
}

class ProviderDirectory {
  const ProviderDirectory(this._query);

  final Future<Map<String, dynamic>> Function(
    String operation,
    Map<String, String> variables,
  ) _query;

  static final _uuid = RegExp(
    r'^(?:[0-9a-f]{32}|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$',
    caseSensitive: false,
  );

  Future<List<ProviderSummary>> list(String categoryId) {
    if (_uuid.hasMatch(categoryId)) {
      return _read('ListCategoryProvidersById', {'categoryId': categoryId});
    }
    return _read('ListCategoryProviders', {'categoryKey': categoryId});
  }

  Future<ProviderSummary?> get(String providerId) async {
    final results =
        await _read('GetActiveProvider', {'providerId': providerId});
    return results.firstOrNull;
  }

  Future<List<ProviderSummary>> _read(
    String operation,
    Map<String, String> variables,
  ) async {
    final data = await _query(operation, variables);
    return (data['providers'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ProviderSummary.fromDirectoryRow)
        .whereType<ProviderSummary>()
        .toList();
  }
}

final providerDirectoryProvider = Provider<ProviderDirectory>((ref) {
  return ProviderDirectory((operation, variables) async {
    final result = await servicePilotDataConnect
        .query<Map<String, dynamic>, Map<String, String>>(
          operation,
          (data) => jsonDecode(data) as Map<String, dynamic>,
          jsonEncode,
          variables,
        )
        .execute();
    return result.data;
  });
});

final categoryProvidersProvider =
    FutureProvider.autoDispose.family<List<ProviderSummary>, String>((ref, id) {
  return ref.watch(providerDirectoryProvider).list(id);
});

final providerProfileProvider =
    FutureProvider.autoDispose.family<ProviderSummary?, String>((ref, id) {
  return ref.watch(providerDirectoryProvider).get(id);
});
