import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/services/company_profile_service.dart';
import 'package:service_pilot/features/providers/services/firestore_provider_service.dart';

void main() {
  const owner = UserModel(
    id: 'company-a',
    fullName: 'Owner A',
    email: 'owner-a@example.com',
    phoneNumber: '',
    role: AppRole.company,
    status: 'active',
  );

  late FakeFirebaseFirestore firestore;
  late CompanyProfileService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = CompanyProfileService(firestore: firestore);
    await firestore.collection('providers').doc(owner.id).set({
      'id': owner.id,
      'providerType': 'company',
      'businessName': 'Old name',
      'coverageAreas': ['Dangkao', 'Prampir Makara'],
      'telegramUrl': 'https://t.me/old_name',
      'status': 'active',
      'isVerified': true,
      'rating': 4.8,
      'categoryIds': ['plumbing'],
    });
  });

  Future<void> save(UserModel actor, {String telegramUrl = ''}) => service.save(
        actor: actor,
        providerId: owner.id,
        businessName: ' New company ',
        description: ' Home repairs ',
        serviceArea: ' Sen Sok, Tuol Kork ',
        telegramUrl: telegramUrl,
        messengerUrl: ' https://m.me/new_company ',
      );

  test('owner saves public fields and clears an optional link', () async {
    expect((await service.load(owner))?.displayName, 'Old name');
    await save(owner);

    final publicService = FirestoreProviderService(firestore: firestore);
    final profile = (await publicService.getProviderById(owner.id))!;
    expect(profile.isCompany, isTrue);
    expect(profile.isApprovedAndActive, isTrue);
    expect(profile.displayName, 'New company');
    expect(profile.description, 'Home repairs');
    expect(profile.formattedCoverageAreas, 'Sen Sok, Tuol Kork');
    expect(profile.telegramUrl, isNull);
    expect(profile.messengerUrl, 'https://m.me/new_company');
    expect(profile.rating, 4.8);
    expect(profile.categoryIds, ['plumbing']);
  });

  test('another company and non-admin company roles cannot save', () async {
    await expectLater(save(owner.copyWith(id: 'company-b')), throwsStateError);
    await expectLater(
      save(owner.copyWith(role: AppRole.companyTechnician)),
      throwsStateError,
    );
    expect((await service.load(owner))?.displayName, 'Old name');
  });

  test('invalid contact link leaves the profile untouched', () async {
    await expectLater(
      save(owner, telegramUrl: 'https://t.me.example.com/contact'),
      throwsArgumentError,
    );
    expect((await service.load(owner))?.telegramUrl, 'https://t.me/old_name');
  });
}
