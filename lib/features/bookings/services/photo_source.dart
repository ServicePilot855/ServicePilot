import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';

enum PhotoOrigin { camera, gallery }

/// Where the booking form gets problem photos from. Replaced in widget tests.
abstract class IPhotoSource {
  /// Lets the customer pick up to [limit] photos. Empty when they cancel.
  Future<List<BookingPhoto>> pick(PhotoOrigin origin, {required int limit});
}

/// Camera and gallery through `image_picker`. Photos are scaled to at most
/// 1920 px and re-encoded, which keeps most well under the 5 MB limit.
class ImagePickerPhotoSource implements IPhotoSource {
  ImagePickerPhotoSource({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const double _maxDimension = 1920;
  static const int _quality = 80;

  @override
  Future<List<BookingPhoto>> pick(
    PhotoOrigin origin, {
    required int limit,
  }) async {
    if (limit < 1) return const [];

    final List<XFile> files;
    if (origin == PhotoOrigin.camera || limit == 1) {
      final file = await _picker.pickImage(
        source: origin == PhotoOrigin.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _quality,
      );
      files = file == null ? const [] : [file];
    } else {
      files = await _picker.pickMultiImage(
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _quality,
        limit: limit,
      );
    }

    return [
      for (final file in files.take(limit))
        BookingPhoto(
          bytes: await file.readAsBytes(),
          name: file.name,
          contentType: file.mimeType ?? _contentTypeFor(file.name),
        ),
    ];
  }

  static String _contentTypeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

final photoSourceProvider = Provider<IPhotoSource>(
  (ref) => ImagePickerPhotoSource(),
);
