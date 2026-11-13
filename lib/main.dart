import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/firebase/firebase_init.dart';
import 'package:service_pilot/core/router/app_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';

void main() async {
  // Required before any async work in main().
  WidgetsFlutterBinding.ensureInitialized();

  // Boot Firebase and configure the Data Connect emulator in debug mode.
  await initializeFirebase();

  runApp(
    // ProviderScope is required by Riverpod — wraps the entire app.
    const ProviderScope(
      child: ServicePilotApp(),
    ),
  );
}

/// Root application widget.
///
/// Reads the [appRouterProvider] and applies the global [AppTheme].
class ServicePilotApp extends ConsumerWidget {
  const ServicePilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ServicePilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
