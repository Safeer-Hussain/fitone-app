import 'package:flutter_test/flutter_test.dart';
import 'package:fitone/domain/entities/barbell_plate.dart';

void main() {
  group('BarbellPlateCalculator Unit Tests', () {
    test('Empty barbell when target equals bar weight (20kg)', () {
      final result = BarbellPlateCalculator.calculate(
        targetWeight: 20.0,
        barWeight: 20.0,
        unit: BarbellUnit.kg,
      );

      expect(result.isExact, isTrue);
      expect(result.totalWeightLoaded, 20.0);
      expect(result.loadedWeightPerSide, 0.0);
      expect(result.platesPerSide, isEmpty);
      expect(result.remainder, 0.0);
      expect(result.summaryDescription, contains('Empty Barbell (20.0kg)'));
    });

    test('Standard Olympic Load: 60kg (20kg bar + 20kg plate per side)', () {
      final result = BarbellPlateCalculator.calculate(
        targetWeight: 60.0,
        barWeight: 20.0,
        unit: BarbellUnit.kg,
      );

      expect(result.isExact, isTrue);
      expect(result.totalWeightLoaded, 60.0);
      expect(result.loadedWeightPerSide, 20.0);
      expect(result.platesPerSide.length, 1);
      expect(result.platesPerSide.first.plate.weight, 20.0);
      expect(result.platesPerSide.first.count, 1);
    });

    test(
      'Standard Olympic Load: 100kg (20kg bar + 1x25kg + 1x15kg per side)',
      () {
        final result = BarbellPlateCalculator.calculate(
          targetWeight: 100.0,
          barWeight: 20.0,
          unit: BarbellUnit.kg,
        );

        expect(result.isExact, isTrue);
        expect(result.totalWeightLoaded, 100.0);
        expect(result.loadedWeightPerSide, 40.0);
        expect(result.platesPerSide.length, 2);
        expect(result.platesPerSide[0].plate.weight, 25.0);
        expect(result.platesPerSide[0].count, 1);
        expect(result.platesPerSide[1].plate.weight, 15.0);
        expect(result.platesPerSide[1].count, 1);
        expect(result.totalPlatesPerSide, 2);
      },
    );

    test('Heavy Olympic Load: 140kg (20kg bar + 2x25kg + 1x10kg per side)', () {
      final result = BarbellPlateCalculator.calculate(
        targetWeight: 140.0,
        barWeight: 20.0,
        unit: BarbellUnit.kg,
      );

      expect(result.isExact, isTrue);
      expect(result.totalWeightLoaded, 140.0);
      expect(result.loadedWeightPerSide, 60.0);
      expect(result.platesPerSide[0].plate.weight, 25.0);
      expect(result.platesPerSide[0].count, 2);
      expect(result.platesPerSide[1].plate.weight, 10.0);
      expect(result.platesPerSide[1].count, 1);
      expect(result.totalPlatesPerSide, 3);
    });

    test(
      'Odd and Fractional Load: 62.5kg (20kg bar + 1x20kg + 1x1.25kg per side)',
      () {
        final result = BarbellPlateCalculator.calculate(
          targetWeight: 62.5,
          barWeight: 20.0,
          unit: BarbellUnit.kg,
        );

        expect(result.isExact, isTrue);
        expect(result.totalWeightLoaded, 62.5);
        expect(result.loadedWeightPerSide, 21.25);
        expect(result.platesPerSide.length, 2);
        expect(result.platesPerSide[0].plate.weight, 20.0);
        expect(result.platesPerSide[0].count, 1);
        expect(result.platesPerSide[1].plate.weight, 1.25);
        expect(result.platesPerSide[1].count, 1);
      },
    );

    test(
      'Odd Load: 77.5kg (20kg bar + 1x25kg + 1x2.5kg + 1x1.25kg per side)',
      () {
        final result = BarbellPlateCalculator.calculate(
          targetWeight: 77.5,
          barWeight: 20.0,
          unit: BarbellUnit.kg,
        );

        expect(result.isExact, isTrue);
        expect(result.totalWeightLoaded, 77.5);
        expect(result.loadedWeightPerSide, 28.75);
        expect(result.platesPerSide.length, 3);
        expect(result.platesPerSide[0].plate.weight, 25.0);
        expect(result.platesPerSide[0].count, 1);
        expect(result.platesPerSide[1].plate.weight, 2.5);
        expect(result.platesPerSide[1].count, 1);
        expect(result.platesPerSide[2].plate.weight, 1.25);
        expect(result.platesPerSide[2].count, 1);
      },
    );

    test('Odd Unachievable Load: 61.0kg with smallest plate 1.25kg leaves 1.0kg remainder', () {
      final result = BarbellPlateCalculator.calculate(
        targetWeight: 61.0,
        barWeight: 20.0,
        unit: BarbellUnit.kg,
      );

      expect(result.isExact, isFalse);
      expect(result.totalWeightLoaded, 60.0);
      expect(result.remainder, 1.0);
      expect(result.loadedWeightPerSide, 20.0);
      expect(result.platesPerSide.length, 1);
      expect(result.platesPerSide.first.plate.weight, 20.0);
    });

    test('Target weight below barbell weight (15kg target with 20kg bar)', () {
      final result = BarbellPlateCalculator.calculate(
        targetWeight: 15.0,
        barWeight: 20.0,
        unit: BarbellUnit.kg,
      );

      expect(result.isExact, isFalse);
      expect(result.totalWeightLoaded, 20.0);
      expect(result.loadedWeightPerSide, 0.0);
      expect(result.platesPerSide, isEmpty);
      expect(result.remainder, 5.0);
    });

    test(
      'Custom Barbell Weight: 15kg Women\'s Olympic Bar with 65kg target',
      () {
        // (65 - 15) / 2 = 25kg per side -> 1x 25kg plate
        final result = BarbellPlateCalculator.calculate(
          targetWeight: 65.0,
          barWeight: 15.0,
          unit: BarbellUnit.kg,
        );

        expect(result.isExact, isTrue);
        expect(result.barWeight, 15.0);
        expect(result.totalWeightLoaded, 65.0);
        expect(result.loadedWeightPerSide, 25.0);
        expect(result.platesPerSide.length, 1);
        expect(result.platesPerSide.first.plate.weight, 25.0);
      },
    );

    test(
      'Imperial (LBS) Standard Load: 135 lbs (45lb bar + 1x45lb per side)',
      () {
        final result = BarbellPlateCalculator.calculate(
          targetWeight: 135.0,
          barWeight: 45.0,
          unit: BarbellUnit.lbs,
        );

        expect(result.isExact, isTrue);
        expect(result.totalWeightLoaded, 135.0);
        expect(result.loadedWeightPerSide, 45.0);
        expect(result.platesPerSide.length, 1);
        expect(result.platesPerSide.first.plate.weight, 45.0);
        expect(result.platesPerSide.first.count, 1);
      },
    );

    test(
      'Imperial (LBS) Standard Load: 225 lbs (45lb bar + 2x45lb per side)',
      () {
        final result = BarbellPlateCalculator.calculate(
          targetWeight: 225.0,
          barWeight: 45.0,
          unit: BarbellUnit.lbs,
        );

        expect(result.isExact, isTrue);
        expect(result.totalWeightLoaded, 225.0);
        expect(result.loadedWeightPerSide, 90.0);
        expect(result.platesPerSide.length, 1);
        expect(result.platesPerSide.first.plate.weight, 45.0);
        expect(result.platesPerSide.first.count, 2);
      },
    );

    test('Imperial (LBS) Complex Load: 185 lbs (45lb bar + 1x45lb + 1x25lb per side)', () {
      final result = BarbellPlateCalculator.calculate(
        targetWeight: 185.0,
        barWeight: 45.0,
        unit: BarbellUnit.lbs,
      );

      expect(result.isExact, isTrue);
      expect(result.totalWeightLoaded, 185.0);
      expect(result.loadedWeightPerSide, 70.0);
      expect(result.platesPerSide.length, 2);
      expect(result.platesPerSide[0].plate.weight, 45.0);
      expect(result.platesPerSide[0].count, 1);
      expect(result.platesPerSide[1].plate.weight, 25.0);
      expect(result.platesPerSide[1].count, 1);
    });

    test('Flattened plates ordered inside-out for visual representation', () {
      final result = BarbellPlateCalculator.calculate(
        targetWeight: 140.0,
        barWeight: 20.0,
        unit: BarbellUnit.kg,
      );

      final flattened = result.flattenedPlatesInsideOut;
      expect(flattened.length, 3);
      expect(flattened[0].weight, 25.0);
      expect(flattened[1].weight, 25.0);
      expect(flattened[2].weight, 10.0);
    });
  });
}
