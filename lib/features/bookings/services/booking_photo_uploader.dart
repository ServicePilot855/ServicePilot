import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';

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
  static String _safeName(String name) => _sanitizeFileName(name);
}

/// Uploads booking problem photos to Cloudinary using an unsigned upload preset.
///
/// Unsigned presets only need [cloudName] and [uploadPreset] (no API secret in
/// client code), so this works on Firebase's free Spark plan without Cloud
/// Functions or Firebase Storage.
class CloudinaryBookingPhotoUploader implements IBookingPhotoUploader {
  CloudinaryBookingPhotoUploader({
    this.cloudName = defaultCloudName,
    this.uploadPreset = defaultUploadPreset,
    this.baseFolder = defaultBaseFolder,
    http.Client? client,
  }) : _injectedClient = client;

  static const String defaultCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'xnljzt9m',
  );
  static const String defaultUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'servicepilot',
  );
  static const String defaultBaseFolder = 'servicepilot/bookings';

  final String cloudName;
  final String uploadPreset;
  final String baseFolder;
  final http.Client? _injectedClient;

  Uri get _uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  @override
  Future<List<String>> upload({
    required String customerId,
    required String bookingId,
    required List<BookingPhoto> photos,
  }) async {
    if (photos.isEmpty) return const <String>[];

    final client = _injectedClient ?? http.Client();
    final ownsClient = _injectedClient == null;
    try {
      final urls = <String>[];
      for (var i = 0; i < photos.length; i++) {
        final photo = photos[i];
        final request = http.MultipartRequest('POST', _uploadUri)
          ..fields['upload_preset'] = uploadPreset
          ..fields['folder'] = '$baseFolder/$customerId/$bookingId'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              photo.bytes,
              filename: '${i + 1}_${_sanitizeFileName(photo.name)}',
            ),
          );

        final streamed = await client.send(request);
        final response = await http.Response.fromStream(streamed);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw BookingSubmissionException(
            'Photo upload failed (${response.statusCode}). Please try again.',
          );
        }

        final decoded = jsonDecode(response.body);
        final secureUrl =
            decoded is Map<String, dynamic> ? decoded['secure_url'] : null;
        if (secureUrl is! String || secureUrl.isEmpty) {
          throw const BookingSubmissionException(
            'Photo upload did not return an image link. Please try again.',
          );
        }
        urls.add(secureUrl);
      }
      return urls;
    } finally {
      if (ownsClient) {
        client.close();
      }
    }
  }
}

String _sanitizeFileName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return cleaned.isEmpty ? 'photo.jpg' : cleaned;
}
