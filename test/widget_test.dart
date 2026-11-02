import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/main.dart';

void main() {
  testWidgets('App smoke test - mounts successfully and navigates to login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ServicePilotApp(),
      ),
    );

    // Initial splash frame
    expect(find.text('ServicePilot'), findsOneWidget);

    // Fast-forward past the splash timer (2.5 seconds)
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Should have transitioned to Login Screen
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
