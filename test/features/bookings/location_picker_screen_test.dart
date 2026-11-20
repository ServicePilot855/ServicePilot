import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/screens/location_picker_screen.dart';
import 'package:service_pilot/l10n/app_localizations.dart';

void main() {
  testWidgets('confirming returns the point under the pin', (tester) async {
    LatLng? result;
    const start = LatLng(11.5449, 104.8922);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => TextButton(
            onPressed: () async =>
                result = await context.push<LatLng>('/pick', extra: start),
            child: const Text('open map'),
          ),
        ),
        GoRoute(
          path: '/pick',
          builder: (_, state) =>
              LocationPickerScreen(initial: state.extra as LatLng?),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.tap(find.text('open map'));
    // Tiles never load in tests, so step through the route transition
    // instead of waiting for everything to settle.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Pin the repair address'), findsOneWidget);
    expect(find.text('OpenStreetMap contributors'), findsOneWidget);

    await tester.tap(find.byKey(const Key('location_picker_confirm')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(result, start);
  });
}
