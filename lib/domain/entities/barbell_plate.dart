import 'package:flutter/material.dart';

enum BarbellUnit { kg, lbs }

class BarbellPlate {
  final double weight;
  final BarbellUnit unit;
  final Color color;
  final Color textColor;
  final double heightFactor;
  final double widthFactor;
  final String label;

  const BarbellPlate({
    required this.weight,
    required this.unit,
    required this.color,
    required this.textColor,
    required this.heightFactor,
    required this.widthFactor,
    required this.label,
  });

  static const List<BarbellPlate> standardOlympicKg = [
    BarbellPlate(
      weight: 25.0,
      unit: BarbellUnit.kg,
      color: Color(0xFFD32F2F),
      textColor: Colors.white,
      heightFactor: 1.0,
      widthFactor: 1.0,
      label: '25',
    ),
    BarbellPlate(
      weight: 20.0,
      unit: BarbellUnit.kg,
      color: Color(0xFF1976D2),
      textColor: Colors.white,
      heightFactor: 1.0,
      widthFactor: 0.95,
      label: '20',
    ),
    BarbellPlate(
      weight: 15.0,
      unit: BarbellUnit.kg,
      color: Color(0xFFFBC02D),
      textColor: Colors.black87,
      heightFactor: 0.88,
      widthFactor: 0.85,
      label: '15',
    ),
    BarbellPlate(
      weight: 10.0,
      unit: BarbellUnit.kg,
      color: Color(0xFF388E3C),
      textColor: Colors.white,
      heightFactor: 0.78,
      widthFactor: 0.75,
      label: '10',
    ),
    BarbellPlate(
      weight: 5.0,
      unit: BarbellUnit.kg,
      color: Color(0xFFECEFF1),
      textColor: Colors.black87,
      heightFactor: 0.65,
      widthFactor: 0.60,
      label: '5',
    ),
    BarbellPlate(
      weight: 2.5,
      unit: BarbellUnit.kg,
      color: Color(0xFF37474F),
      textColor: Colors.white,
      heightFactor: 0.52,
      widthFactor: 0.45,
      label: '2.5',
    ),
    BarbellPlate(
      weight: 1.25,
      unit: BarbellUnit.kg,
      color: Color(0xFF90A4AE),
      textColor: Colors.black87,
      heightFactor: 0.42,
      widthFactor: 0.35,
      label: '1.25',
    ),
  ];

  static const List<BarbellPlate> standardOlympicLbs = [
    BarbellPlate(
      weight: 45.0,
      unit: BarbellUnit.lbs,
      color: Color(0xFF1976D2),
      textColor: Colors.white,
      heightFactor: 1.0,
      widthFactor: 1.0,
      label: '45',
    ),
    BarbellPlate(
      weight: 35.0,
      unit: BarbellUnit.lbs,
      color: Color(0xFFFBC02D),
      textColor: Colors.black87,
      heightFactor: 0.88,
      widthFactor: 0.85,
      label: '35',
    ),
    BarbellPlate(
      weight: 25.0,
      unit: BarbellUnit.lbs,
      color: Color(0xFF388E3C),
      textColor: Colors.white,
      heightFactor: 0.78,
      widthFactor: 0.75,
      label: '25',
    ),
    BarbellPlate(
      weight: 10.0,
      unit: BarbellUnit.lbs,
      color: Color(0xFF37474F),
      textColor: Colors.white,
      heightFactor: 0.65,
      widthFactor: 0.60,
      label: '10',
    ),
    BarbellPlate(
      weight: 5.0,
      unit: BarbellUnit.lbs,
      color: Color(0xFFECEFF1),
      textColor: Colors.black87,
      heightFactor: 0.52,
      widthFactor: 0.45,
      label: '5',
    ),
    BarbellPlate(
      weight: 2.5,
      unit: BarbellUnit.lbs,
      color: Color(0xFF90A4AE),
      textColor: Colors.black87,
      heightFactor: 0.42,
      widthFactor: 0.35,
      label: '2.5',
    ),
  ];
}

class LoadedPlate {
  final BarbellPlate plate;
  final int count;

  const LoadedPlate({required this.plate, required this.count});

  double get totalWeight =>
      double.parse((plate.weight * count).toStringAsFixed(4));
}

class BarbellPlateResult {
  final double targetWeight;
  final double barWeight;
  final BarbellUnit unit;
  final List<LoadedPlate> platesPerSide;
  final double loadedWeightPerSide;
  final double totalWeightLoaded;
  final double remainder;
  final bool isExact;

  const BarbellPlateResult({
    required this.targetWeight,
    required this.barWeight,
    required this.unit,
    required this.platesPerSide,
    required this.loadedWeightPerSide,
    required this.totalWeightLoaded,
    required this.remainder,
    required this.isExact,
  });

  int get totalPlatesPerSide =>
      platesPerSide.fold(0, (sum, p) => sum + p.count);

  List<BarbellPlate> get flattenedPlatesInsideOut {
    final list = <BarbellPlate>[];
    for (final loaded in platesPerSide) {
      for (var i = 0; i < loaded.count; i++) {
        list.add(loaded.plate);
      }
    }
    return list;
  }

  String get summaryDescription {
    final unitStr = unit == BarbellUnit.kg ? 'kg' : 'lb';
    if (platesPerSide.isEmpty) {
      return 'Empty Barbell (${barWeight.toStringAsFixed(1)}$unitStr)';
    }
    final breakdown = platesPerSide
        .map((p) => '${p.count}x ${p.plate.label}$unitStr')
        .join(', ');
    return '${totalWeightLoaded.toStringAsFixed(1)}$unitStr total: ${barWeight.toStringAsFixed(1)}$unitStr bar + [$breakdown] per side';
  }
}

class BarbellPlateCalculator {
  static const double defaultBarWeightKg = 20.0;
  static const double defaultBarWeightLbs = 45.0;

  static BarbellPlateResult calculate({
    required double targetWeight,
    double? barWeight,
    BarbellUnit unit = BarbellUnit.kg,
    List<BarbellPlate>? availablePlates,
  }) {
    final cleanTarget = double.parse(targetWeight.toStringAsFixed(4));
    final defaultBar = unit == BarbellUnit.kg
        ? defaultBarWeightKg
        : defaultBarWeightLbs;
    final effectiveBarWeight = double.parse(
      (barWeight ?? defaultBar).toStringAsFixed(4),
    );

    final platesPool = List<BarbellPlate>.from(
      availablePlates ??
          (unit == BarbellUnit.kg
              ? BarbellPlate.standardOlympicKg
              : BarbellPlate.standardOlympicLbs),
    )..sort((a, b) => b.weight.compareTo(a.weight));

    if (cleanTarget <= effectiveBarWeight) {
      final remainder = double.parse(
        (effectiveBarWeight - cleanTarget).toStringAsFixed(4),
      );
      return BarbellPlateResult(
        targetWeight: cleanTarget,
        barWeight: effectiveBarWeight,
        unit: unit,
        platesPerSide: const [],
        loadedWeightPerSide: 0.0,
        totalWeightLoaded: effectiveBarWeight,
        remainder: remainder,
        isExact: cleanTarget == effectiveBarWeight,
      );
    }

    final targetPlatesTotal = double.parse(
      (cleanTarget - effectiveBarWeight).toStringAsFixed(4),
    );
    var remainingPerSide = double.parse(
      (targetPlatesTotal / 2.0).toStringAsFixed(4),
    );

    final loadedList = <LoadedPlate>[];

    for (final plate in platesPool) {
      if (plate.weight <= 0) continue;
      if (remainingPerSide >= plate.weight - 0.0001) {
        final count = (remainingPerSide / plate.weight).floor();
        if (count > 0) {
          loadedList.add(LoadedPlate(plate: plate, count: count));
          remainingPerSide = double.parse(
            (remainingPerSide - (count * plate.weight)).toStringAsFixed(4),
          );
        }
      }
    }

    final loadedWeightPerSide = loadedList.fold<double>(
      0.0,
      (sum, p) => double.parse((sum + p.totalWeight).toStringAsFixed(4)),
    );

    final totalLoaded = double.parse(
      (effectiveBarWeight + (loadedWeightPerSide * 2.0)).toStringAsFixed(4),
    );
    final remainder = double.parse(
      (cleanTarget - totalLoaded).abs().toStringAsFixed(4),
    );
    final isExact = remainder < 0.001;

    return BarbellPlateResult(
      targetWeight: cleanTarget,
      barWeight: effectiveBarWeight,
      unit: unit,
      platesPerSide: List.unmodifiable(loadedList),
      loadedWeightPerSide: loadedWeightPerSide,
      totalWeightLoaded: totalLoaded,
      remainder: remainder,
      isExact: isExact,
    );
  }
}
