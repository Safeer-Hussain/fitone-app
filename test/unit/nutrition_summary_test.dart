import 'package:fitone/domain/entities/nutrition_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Daily Nutrition & Hydration Calculation Tests', () {
    test(
      'Calculates consumed totals and macro progress percentages accurately',
      () {
        final now = DateTime.now();
        final meals = [
          NutritionLogItem(
            id: 'n_1',
            dateStr: '2026-11-04',
            mealType: 'Breakfast',
            foodName: 'Oats & Whey',
            calories: 500.0,
            proteinG: 45.0,
            carbsG: 60.0,
            fatG: 8.0,
            timestamp: now,
          ),
          NutritionLogItem(
            id: 'n_2',
            dateStr: '2026-11-04',
            mealType: 'Lunch',
            foodName: 'Chicken & Rice',
            calories: 700.0,
            proteinG: 65.0,
            carbsG: 70.0,
            fatG: 12.0,
            timestamp: now,
          ),
        ];

        final hydration = [
          HydrationLogItem(
            id: 'h_1',
            dateStr: '2026-11-04',
            amountMl: 500,
            timestamp: now,
          ),
          HydrationLogItem(
            id: 'h_2',
            dateStr: '2026-11-04',
            amountMl: 1000,
            timestamp: now,
          ),
        ];

        final summary = DailyNutritionSummary(
          dateStr: '2026-11-04',
          targetCalories: 2400.0,
          targetProteinG: 175.0,
          targetCarbsG: 240.0,
          targetFatG: 65.0,
          targetWaterMl: 3000,
          mealItems: meals,
          waterItems: hydration,
        );

        expect(summary.consumedCalories, equals(1200.0));
        expect(summary.consumedProteinG, equals(110.0));
        expect(summary.consumedCarbsG, equals(130.0));
        expect(summary.consumedFatG, equals(20.0));
        expect(summary.consumedWaterMl, equals(1500));

        expect(summary.calorieProgress, equals(0.5));
        expect(summary.waterProgress, equals(0.5));
        expect(summary.proteinProgress, closeTo(110.0 / 175.0, 0.01));
      },
    );
  });
}
