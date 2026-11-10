import 'package:fitone/domain/entities/nutrition_day.dart';
import 'package:fitone/presentation/dashboard/widgets/ecg_waveform_card.dart';
import 'package:fitone/presentation/dashboard/widgets/readiness_ring.dart';
import 'package:fitone/presentation/nutrition/widgets/macro_progress_ring.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core Presentation Widget Tests', () {
    testWidgets('ReadinessRing renders score and metric labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadinessRing(score: 92, hrvMs: 74, restingHr: 52),
          ),
        ),
      );

      expect(find.text('RECOVERY & READINESS'), findsOneWidget);
      expect(find.text('92'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(find.text('52'), findsOneWidget);
      expect(find.text('Optimal Readiness'), findsOneWidget);
    });

    testWidgets('MacroProgressRing displays calories and remaining target', (
      WidgetTester tester,
    ) async {
      final summary = DailyNutritionSummary(
        dateStr: '2026-11-04',
        targetCalories: 2400.0,
        targetProteinG: 175.0,
        targetCarbsG: 240.0,
        targetFatG: 65.0,
        targetWaterMl: 3000,
        mealItems: [
          NutritionLogItem(
            id: 'n_1',
            dateStr: '2026-11-04',
            mealType: 'Breakfast',
            foodName: 'Oatmeal',
            calories: 600.0,
            proteinG: 40.0,
            carbsG: 80.0,
            fatG: 10.0,
            timestamp: DateTime(2026, 11, 4),
          ),
        ],
        waterItems: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MacroProgressRing(summary: summary)),
        ),
      );

      expect(find.text('DAILY ENERGY & MACROS'), findsOneWidget);
      expect(find.text('600'), findsOneWidget);
      expect(find.text('1800 kcal left'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
    });

    testWidgets(
      'EcgWaveformCard renders with full container width and valid telemetry',
      (WidgetTester tester) async {
        const containerWidth = 450.0;
        final samples = List.generate(40, (i) => (i % 5 == 0) ? 1.2 : 0.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: containerWidth,
                child: EcgWaveformCard(
                  ecgBuffer: samples,
                  heartRate: 74,
                  spo2: 98,
                  skinTempDelta: 0.2,
                  signalQuality: 99,
                ),
              ),
            ),
          ),
        );

        final cardFinder = find.byType(EcgWaveformCard);
        expect(cardFinder, findsOneWidget);
        final cardSize = tester.getSize(cardFinder);
        expect(cardSize.width, equals(containerWidth));

        final chartFinder = find.byType(LineChart);
        expect(chartFinder, findsOneWidget);
        final chartSize = tester.getSize(chartFinder);
        expect(chartSize.width, equals(containerWidth));

        expect(find.text('LIVE PPG TELEMETRY'), findsOneWidget);
        expect(find.text('74'), findsOneWidget);
        expect(find.text('98%'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
