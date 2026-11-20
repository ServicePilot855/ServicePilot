import 'package:firebase_storage/firebase_storage.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';

/// Uploads a booking's problem photos and returns their download links.
abstract class IBookingPhotoUploader {
  Future<List<String>> upload({
    required String customerId,
    required String bookingId,
    required List<BookingPhoto> photos,
  });
}

/// Stores photos in Firebase Storage under
/// `bookings/{customerId}/{bookingId}/`.
///
/// The customer ID is part of the path because the booking document does not
/// exist yet while its photos upload; `storage.rules` uses it to check that
/// customers only write into their own folder.
class FirebaseBookingPhotoUploader implements IBookingPhotoUploader {
  FirebaseBookingPhotoUploader({FirebaseStorage? storage})
      : _injectedStorage = storage;

  final FirebaseStorage? _injectedStorage;

  FirebaseStorage get _storage => _injectedStorage ?? FirebaseStorage.instance;

  @override
  Future<List<String>> upload({
    required String customerId,
    required String bookingId,
    required List<BookingPhoto> photos,
  }) async {
    final folder = _storage.ref('bookings/$customerId/$bookingId');
    final urls = <String>[];
    for (var i = 0; i < photos.length; i++) {
      final photo = photos[i];
      final ref = folder.child('${i + 1}_${_safeName(photo.name)}');
      await ref.putData(
        photo.bytes,
        SettableMetadata(contentType: photo.contentType),
      );
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  /// Keeps letters, digits, dots, dashes and underscores; the rest become `_`.
  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'photo.jpg' : cleaned;
  }
}
