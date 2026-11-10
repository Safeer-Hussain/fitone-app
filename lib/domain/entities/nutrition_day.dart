class NutritionLogItem {
  final String id;
  final String dateStr;
  final String mealType;
  final String foodName;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime timestamp;

  const NutritionLogItem({
    required this.id,
    required this.dateStr,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.timestamp,
  });

  factory NutritionLogItem.fromMap(Map<String, dynamic> map) {
    return NutritionLogItem(
      id: map['id'] as String,
      dateStr: map['date_str'] as String,
      mealType: map['meal_type'] as String,
      foodName: map['food_name'] as String,
      calories: (map['calories'] as num).toDouble(),
      proteinG: (map['protein_g'] as num).toDouble(),
      carbsG: (map['carbs_g'] as num).toDouble(),
      fatG: (map['fat_g'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_str': dateStr,
      'meal_type': mealType,
      'food_name': foodName,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class HydrationLogItem {
  final String id;
  final String dateStr;
  final int amountMl;
  final DateTime timestamp;

  const HydrationLogItem({
    required this.id,
    required this.dateStr,
    required this.amountMl,
    required this.timestamp,
  });

  factory HydrationLogItem.fromMap(Map<String, dynamic> map) {
    return HydrationLogItem(
      id: map['id'] as String,
      dateStr: map['date_str'] as String,
      amountMl: (map['amount_ml'] as num).toInt(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_str': dateStr,
      'amount_ml': amountMl,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class DailyNutritionSummary {
  final String dateStr;
  final double targetCalories;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;
  final int targetWaterMl;
  final List<NutritionLogItem> mealItems;
  final List<HydrationLogItem> waterItems;

  const DailyNutritionSummary({
    required this.dateStr,
    this.targetCalories = 2400.0,
    this.targetProteinG = 175.0,
    this.targetCarbsG = 240.0,
    this.targetFatG = 65.0,
    this.targetWaterMl = 3000,
    required this.mealItems,
    required this.waterItems,
  });

  double get consumedCalories =>
      mealItems.fold(0.0, (acc, item) => acc + item.calories);
  double get consumedProteinG =>
      mealItems.fold(0.0, (acc, item) => acc + item.proteinG);
  double get consumedCarbsG =>
      mealItems.fold(0.0, (acc, item) => acc + item.carbsG);
  double get consumedFatG =>
      mealItems.fold(0.0, (acc, item) => acc + item.fatG);
  int get consumedWaterMl =>
      waterItems.fold(0, (acc, item) => acc + item.amountMl);

  double get calorieProgress => targetCalories > 0
      ? (consumedCalories / targetCalories).clamp(0.0, 1.0)
      : 0.0;
  double get proteinProgress => targetProteinG > 0
      ? (consumedProteinG / targetProteinG).clamp(0.0, 1.0)
      : 0.0;
  double get carbsProgress =>
      targetCarbsG > 0 ? (consumedCarbsG / targetCarbsG).clamp(0.0, 1.0) : 0.0;
  double get fatProgress =>
      targetFatG > 0 ? (consumedFatG / targetFatG).clamp(0.0, 1.0) : 0.0;
  double get waterProgress => targetWaterMl > 0
      ? (consumedWaterMl / targetWaterMl).clamp(0.0, 1.0)
      : 0.0;
}
