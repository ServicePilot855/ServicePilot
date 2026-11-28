import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:service_pilot/core/firebase/firebase_init.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';

typedef AdminAccountSummary = ({String role, String status});

final adminAccountLookupServiceProvider = Provider<AdminAccountLookupService>(
  (ref) {
    final auth = FirebaseAuth.instance;
    final client = http.Client();
    ref.onDispose(client.close);
    final emulatorHost =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : firestoreEmulatorHost;
    return AdminAccountLookupService(
      client: client,
      projectId: auth.app.options.projectId,
      origin: firestoreEmulatorEnabled
          ? Uri.http('$emulatorHost:$firestoreEmulatorPort')
          : Uri.https('firestore.googleapis.com'),
      readIdToken: (actorId) async {
        final user = auth.currentUser;
        return user != null && user.uid == actorId ? user.getIdToken() : null;
      },
    );
  },
);

class AdminAccountLookupService {
  AdminAccountLookupService({
    required http.Client client,
    required String projectId,
    required Uri origin,
    required Future<String?> Function(String actorId) readIdToken,
  })  : _client = client,
        _root = 'projects/$projectId/databases/(default)/documents',
        _origin = origin,
        _readIdToken = readIdToken;

  final http.Client _client;
  final String _root;
  final Uri _origin;
  final Future<String?> Function(String actorId) _readIdToken;

  static bool isValidAccountId(String input) {
    final id = input.trim();
    return id.isNotEmpty &&
        id.length <= 128 &&
        id != '.' &&
        id != '..' &&
        !id.contains('/') &&
        !id.contains(RegExp(r'[\x00-\x1f\x7f]'));
  }

  Future<AdminAccountSummary?> lookup(
    String accountId, {
    required UserModel actor,
  }) async {
    if (!actor.isAdmin || !actor.isActive) throw _accessDenied();
    if (!isValidAccountId(accountId)) {
      throw ArgumentError('Invalid account ID');
    }
    final token = await _readIdToken(actor.id);
    if (token == null || token.isEmpty) throw _accessDenied();

    // The Firestore SDK has no field projection. Ask the server for two fields.
    final response = await _client
        .post(
          _origin.replace(path: '/v1/$_root:runQuery'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'structuredQuery': {
              'select': {
                'fields': [
                  {'fieldPath': 'role'},
                  {'fieldPath': 'status'},
                ],
              },
              'from': [
                {'collectionId': 'users'},
              ],
              'where': {
                'fieldFilter': {
                  'field': {'fieldPath': '__name__'},
                  'op': 'EQUAL',
                  'value': {
                    'referenceValue': '$_root/users/${accountId.trim()}',
                  },
                },
              },
              'limit': 1,
            },
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw _accessDenied();
    }
    if (response.statusCode != 200) {
      throw StateError('Account lookup request failed');
    }
    final rows = jsonDecode(response.body) as List<dynamic>;
    for (final row in rows) {
      if (row case {'error': _}) {
        throw StateError('Account lookup query failed');
      }
      if (row
          case {
            'document': {
              'fields': {
                'role': {'stringValue': final String role},
                'status': {'stringValue': final String status},
              },
            }
          }) {
        return (role: role, status: status);
      }
      if (row case {'document': _}) {
        throw const FormatException('Incomplete account summary');
      }
    }
    return null;
  }

  FirebaseException _accessDenied() =>
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
}
