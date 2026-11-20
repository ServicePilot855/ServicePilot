import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/providers/provider_directory.dart';

void main() {
  Map<String, dynamic> provider(
    String id, {
    String? status = 'ACTIVE',
    String? type = 'INDEPENDENT',
    String area = 'Sen Sok',
  }) =>
      {
        'uid': id,
        'providerName': id,
        'providerType': type,
        'providerStatus': status,
        'serviceArea': area,
      };

  test('requests the selected category and excludes ineligible profiles',
      () async {
    final directory = ProviderDirectory((operation, variables) async {
      expect(operation, 'ListCategoryProviders');
      expect(variables, {'categoryKey': 'cat-plumbing'});
      return {
        'providers': [
          provider('technician'),
          provider('company', type: 'COMPANY'),
          provider('pending', status: 'PENDING_VERIFICATION'),
          provider('inactive', status: 'INACTIVE'),
          provider('legacy', status: null),
          provider('unknown-type', type: 'OTHER'),
          provider('incomplete', area: ' '),
        ],
      };
    });

    final providers = await directory.list('cat-plumbing');
    expect(providers.map((entry) => entry.id), ['technician', 'company']);
    expect(providers.map((entry) => entry.type), [
      ProviderType.independent,
      ProviderType.company,
    ]);
    expect(providers.first.serviceArea, 'Sen Sok');
  });

  for (final id in [
    '11111111-0000-0000-0000-000000000001',
    '11111111000000000000000000000001',
  ]) {
    test('supports database category ID $id', () async {
      final directory = ProviderDirectory((operation, variables) async {
        expect(operation, 'ListCategoryProvidersById');
        expect(variables, {'categoryId': id});
        return {'providers': []};
      });

      expect(await directory.list(id), isEmpty);
    });
  }

  test('a profile that is no longer active is unavailable by direct link',
      () async {
    final directory = ProviderDirectory((operation, variables) async {
      expect(operation, 'GetActiveProvider');
      expect(variables, {'providerId': 'technician'});
      return {
        'providers': [provider('technician', status: 'INACTIVE')]
      };
    });

    expect(await directory.get('technician'), isNull);
  });
}
