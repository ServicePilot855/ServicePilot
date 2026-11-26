import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/services/firestore_offering_service.dart';

class _SwitchableFirestore extends FakeFirebaseFirestore {
  bool denyAccess = false;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    if (denyAccess) {
      throw FirebaseException(
          plugin: 'cloud_firestore', code: 'permission-denied');
    }
    return super.collection(collectionPath);
  }
}

void main() {
  const offering = OfferingModel(
    id: '',
    providerId: 'provider-1',
    providerName: 'Provider 1',
    categoryId: 'cat-ac',
    categoryName: 'Air Conditioning',
    title: 'Split Unit Wash',
    description: 'Deep cleaning and drain inspection.',
    pricingMode: OfferingPricingMode.fixed,
    price: 25.49,
  );

  test('fixed offers persist with their saved price and generated ID',
      () async {
    final firestore = FakeFirebaseFirestore();
    final service = FirestoreOfferingService(firestore: firestore);
    final saved = await service.createOffering(offering);

    final stored = await firestore.collection('offerings').doc(saved.id).get();
    expect(stored.data(), containsPair('price', 25.49));
    expect(stored.data(), containsPair('providerId', 'provider-1'));
    expect(stored.data(), containsPair('categoryId', 'cat-ac'));
    expect(stored.data(), containsPair('pricingMode', 'fixed'));
    expect((await service.getOfferings(providerId: 'provider-1')).single.id,
        saved.id);
    expect(await service.getOfferings(providerId: 'provider-2'), isEmpty);
  });

  test('a denied fixed publish never succeeds via the in-memory store',
      () async {
    final service = FirestoreOfferingService(
      firestore: _SwitchableFirestore()..denyAccess = true,
      fallbackOfferings: [],
    );
    await expectLater(
        service.createOffering(offering), throwsA(isA<FirebaseException>()));
    expect(await service.getOfferings(), isEmpty);
  });

  test('a confirmed fixed publish is still visible if the next read fails',
      () async {
    final firestore = _SwitchableFirestore();
    final service = FirestoreOfferingService(
      firestore: firestore,
      fallbackOfferings: [],
    );
    final saved = await service.createOffering(offering);
    firestore.denyAccess = true;

    expect(
      (await service.getOfferings(providerId: offering.providerId)).single.id,
      saved.id,
    );
  });

  test('invalid fixed prices never reach Firestore', () async {
    final firestore = FakeFirebaseFirestore();
    final service = FirestoreOfferingService(firestore: firestore);
    await expectLater(
      service.createOffering(offering.copyWith(price: 0.001)),
      throwsArgumentError,
    );
    expect((await firestore.collection('offerings').get()).docs, isEmpty);
  });
}
