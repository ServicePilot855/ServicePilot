import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/services/firestore_provider_service.dart';
import 'package:service_pilot/features/providers/services/independent_profile_service.dart';

void main() {
  const owner = UserModel(
    id: 'tech-a',
    fullName: 'Virak Chan',
    email: 'virak@example.com',
    phoneNumber: '+85587654321',
    role: AppRole.independentProvider,
    status: 'active',
    serviceArea: 'Toul Kork',
  );

  late FakeFirebaseFirestore firestore;
  late IndependentProfileService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = IndependentProfileService(firestore: firestore);
    await firestore.collection('providers').doc(owner.id).set({
      'id': owner.id,
      'providerType': 'independent',
      'name': 'Old Name',
      'fullName': 'Old Name',
      'description': 'Old bio',
      'serviceArea': 'Toul Kork',
      'coverageAreas': ['Toul Kork'],
      'telegramUrl': 'https://t.me/old_tech',
      'status': 'active',
      'isVerified': true,
      'rating': 4.9,
      'categoryIds': ['cat-ac'],
    });
    await firestore.collection('users').doc(owner.id).set(owner.toJson());
  });

  Future<void> save(UserModel actor, {String telegramUrl = ''}) => service.save(
        actor: actor,
        providerId: owner.id,
        fullName: ' Virak New Name ',
        description: ' Updated bio with specialized skills ',
        serviceArea: ' Sen Sok, Toul Kork ',
        telegramUrl: telegramUrl,
        messengerUrl: ' https://m.me/virak_new ',
      );

  test('independent technician saves public fields and updates users collection',
      () async {
    expect((await service.load(owner))?.name, 'Old Name');
    await save(owner);

    final publicService = FirestoreProviderService(firestore: firestore);
    final profile = (await publicService.getProviderById(owner.id))!;
    expect(profile.isIndependent, isTrue);
    expect(profile.isApprovedAndActive, isTrue);
    expect(profile.name, 'Virak New Name');
    expect(profile.description, 'Updated bio with specialized skills');
    expect(profile.formattedCoverageAreas, 'Sen Sok, Toul Kork');
    expect(profile.telegramUrl, isNull);
    expect(profile.messengerUrl, 'https://m.me/virak_new');
    expect(profile.rating, 4.9);
    expect(profile.categoryIds, ['cat-ac']);

    final userDoc = await firestore.collection('users').doc(owner.id).get();
    expect(userDoc.data()?['fullName'], 'Virak New Name');
    expect(userDoc.data()?['serviceArea'], 'Sen Sok, Toul Kork');
  });

  test('another technician and other roles cannot save changes', () async {
    await expectLater(save(owner.copyWith(id: 'tech-b')), throwsStateError);
    await expectLater(
      save(owner.copyWith(role: AppRole.homeowner)),
      throwsStateError,
    );
    await expectLater(
      save(owner.copyWith(role: AppRole.company)),
      throwsStateError,
    );
    expect((await service.load(owner))?.name, 'Old Name');
  });

  test('suspended technician cannot edit profile', () async {
    await expectLater(
      save(owner.copyWith(status: 'suspended')),
      throwsStateError,
    );
  });

  test('invalid contact link leaves the profile untouched', () async {
    await expectLater(
      save(owner, telegramUrl: 'https://telegram.me/invalid'),
      throwsArgumentError,
    );
    expect((await service.load(owner))?.telegramUrl, 'https://t.me/old_tech');
  });

  test('empty name or service area throws ArgumentError', () async {
    await expectLater(
      service.save(
        actor: owner,
        providerId: owner.id,
        fullName: '   ',
        description: 'Valid description',
        serviceArea: 'Toul Kork',
        telegramUrl: '',
        messengerUrl: '',
      ),
      throwsArgumentError,
    );
    await expectLater(
      service.save(
        actor: owner,
        providerId: owner.id,
        fullName: 'Valid Name',
        description: 'Valid description',
        serviceArea: '',
        telegramUrl: '',
        messengerUrl: '',
      ),
      throwsArgumentError,
    );
  });
}
