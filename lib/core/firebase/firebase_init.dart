import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

FirebaseDataConnect get servicePilotDataConnect =>
    FirebaseDataConnect.instanceFor(
      connectorConfig: ConnectorConfig(
        'us-central1',
        'servicepilot-connector',
        'servicepilot-service',
      ),
    );

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
    const useAuthEmulator =
        bool.fromEnvironment('USE_AUTH_EMULATOR', defaultValue: false);
    if (useAuthEmulator) {
      try {
        await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      } catch (e) {
        debugPrint('Auth emulator init skipped: $e');
      }
    }

    const useDataConnectEmulator =
        bool.fromEnvironment('USE_DATACONNECT_EMULATOR');
    if (useDataConnectEmulator) {
      servicePilotDataConnect.useDataConnectEmulator('127.0.0.1', 9399);
    }
  }
}
