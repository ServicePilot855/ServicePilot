import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initializes Firebase and configures local emulators when running in debug.
///
/// Call this once at app startup, before [runApp].
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // In debug builds, optionally connect to local emulators
  if (kDebugMode) {
    // Optional Auth emulator support via: --dart-define=USE_AUTH_EMULATOR=true
    const useAuthEmulator = bool.fromEnvironment('USE_AUTH_EMULATOR', defaultValue: false);
    if (useAuthEmulator) {
      try {
        await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      } catch (e) {
        debugPrint('Auth emulator init skipped: $e');
      }
    }

    // Optional Firestore emulator support via: --dart-define=USE_FIRESTORE_EMULATOR=true
    const useFirestoreEmulator = bool.fromEnvironment('USE_FIRESTORE_EMULATOR', defaultValue: false);
    if (useFirestoreEmulator) {
      try {
        FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      } catch (e) {
        debugPrint('Firestore emulator init skipped: $e');
      }
    }

    // Connect to Data Connect emulator if available
    try {
      FirebaseDataConnect.instanceFor(
        app: Firebase.app(),
        connectorConfig: ConnectorConfig(
          'us-central1',
          'servicepilot-connector',
          'servicepilot-855',
        ),
      ).useDataConnectEmulator('127.0.0.1', 9399);
    } catch (e) {
      debugPrint('DataConnect emulator init skipped: $e');
    }
  }
}
