import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/services/booking_photo_uploader.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';

BookingPhoto _photo(String name, [List<int> bytes = const [1, 2, 3]]) =>
    BookingPhoto(bytes: Uint8List.fromList(bytes), name: name);

void main() {
  group('CloudinaryBookingPhotoUploader', () {
    test('returns empty list without making HTTP requests when photos is empty',
        () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      });

      final uploader = CloudinaryBookingPhotoUploader(client: client);
      final urls = await uploader.upload(
        customerId: 'cust-1',
        bookingId: 'book-1',
        photos: const [],
      );

      expect(urls, isEmpty);
      expect(calls, 0);
    });

    test('uploads each photo to Cloudinary unsigned preset and returns URLs',
        () async {
      final requests = <http.Request>[];
      var index = 0;
      final client = MockClient((request) async {
        requests.add(request);
        index++;
        return http.Response(
          jsonEncode({
            'secure_url':
                'https://res.cloudinary.com/xnljzt9m/image/upload/v1/servicepilot/bookings/cust-1/book-1/photo_$index.jpg',
          }),
          200,
        );
      });

      final uploader = CloudinaryBookingPhotoUploader(client: client);
      final urls = await uploader.upload(
        customerId: 'cust-1',
        bookingId: 'book-1',
        photos: [
          _photo('leak 1.jpg'),
          _photo('pipe@2.png'),
        ],
      );

      expect(requests, hasLength(2));
      for (final req in requests) {
        expect(req.method, 'POST');
        expect(
          req.url.toString(),
          'https://api.cloudinary.com/v1_1/xnljzt9m/image/upload',
        );
        expect(req.body, contains('name="upload_preset"'));
        expect(req.body, contains('servicepilot'));
        expect(req.body, contains('servicepilot/bookings/cust-1/book-1'));
      }
      expect(requests[0].body, contains('1_leak_1.jpg'));
      expect(requests[1].body, contains('2_pipe_2.png'));
      expect(urls, [
        'https://res.cloudinary.com/xnljzt9m/image/upload/v1/servicepilot/bookings/cust-1/book-1/photo_1.jpg',
        'https://res.cloudinary.com/xnljzt9m/image/upload/v1/servicepilot/bookings/cust-1/book-1/photo_2.jpg',
      ]);
    });

    test('throws BookingSubmissionException when Cloudinary returns non-2xx',
        () async {
      final client = MockClient(
        (_) async => http.Response('{"error":{"message":"Invalid preset"}}', 400),
      );
      final uploader = CloudinaryBookingPhotoUploader(client: client);

      await expectLater(
        () => uploader.upload(
          customerId: 'cust-1',
          bookingId: 'book-1',
          photos: [_photo('leak.jpg')],
        ),
        throwsA(isA<BookingSubmissionException>()),
      );
    });

    test('throws BookingSubmissionException when secure_url is missing',
        () async {
      final client = MockClient((_) async => http.Response('{}', 200));
      final uploader = CloudinaryBookingPhotoUploader(client: client);

      await expectLater(
        () => uploader.upload(
          customerId: 'cust-1',
          bookingId: 'book-1',
          photos: [_photo('leak.jpg')],
        ),
        throwsA(isA<BookingSubmissionException>()),
      );
    });
  });
}
