import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initializes Firebase and configures the Data Connect connector.
///
/// Call this once at app startup, before [runApp].
/// In debug mode, Data Connect talks to the local emulator (port 9399).
/// In release mode, traffic goes to production Cloud SQL.
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // In debug builds, talk to the local Data Connect emulator.
  // In release builds, traffic goes straight to Cloud SQL.
  if (kDebugMode) {
    FirebaseDataConnect.instanceFor(
      app: Firebase.app(),
      connectorConfig: ConnectorConfig(
        'us-central1',
        'servicepilot-connector',
        'servicepilot-855',
      ),
    ).useDataConnectEmulator('127.0.0.1', 9399);
  }
}
