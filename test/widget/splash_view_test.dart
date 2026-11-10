import 'package:fitone/presentation/splash/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplashView Animation and Route Lifecycle Tests', () {
    testWidgets(
      'Displays brand emblem, pulsing animation, and sequential telemetry statuses',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SplashView(
              totalDuration: Duration(milliseconds: 900),
              targetDestination: Scaffold(
                body: Center(child: Text('Navigation Shell Ready')),
              ),
            ),
          ),
        );

        // Verify initial frame
        expect(find.text('FITONE'), findsOneWidget);
        expect(find.text('BIOMETRIC SMART-RING ECOSYSTEM'), findsOneWidget);
        expect(
          find.text('Initializing SQLite telemetry cache...'),
          findsOneWidget,
        );

        // Step forward into Phase 2
        await tester.pump(const Duration(milliseconds: 320));
        expect(
          find.text('Mounting native BLE platform channels...'),
          findsOneWidget,
        );

        // Step forward into Phase 3
        await tester.pump(const Duration(milliseconds: 320));
        expect(find.text('Fitone Ecosystem Ready.'), findsOneWidget);

        // Complete lifecycle and transition
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.text('Navigation Shell Ready'), findsOneWidget);
        expect(
          find.text('Initializing SQLite telemetry cache...'),
          findsNothing,
        );
      },
    );
  });
}
