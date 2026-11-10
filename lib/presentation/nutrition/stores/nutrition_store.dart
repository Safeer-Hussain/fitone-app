import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/nutrition_day.dart';
import '../../../domain/repositories/nutrition_repository.dart';

class NutritionStore {
  final NutritionRepository nutritionRepository;

  NutritionStore({required this.nutritionRepository});

  final _isLoading = Observable<bool>(false);
  bool get isLoading => _isLoading.value;

  final _hasError = Observable<bool>(false);
  bool get hasError => _hasError.value;

  final _dailySummary = Observable<DailyNutritionSummary?>(null);
  DailyNutritionSummary? get dailySummary => _dailySummary.value;

  final _selectedDateStr = Observable<String>('');
  String get selectedDateStr => _selectedDateStr.value;

  final _waterStreakDays = Observable<int>(14);
  int get waterStreakDays => _waterStreakDays.value;

  void initialize() {
    final now = DateTime.now();
    _selectedDateStr.value =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    loadDailySummary();
  }

  Future<void> loadDailySummary() async {
    runInAction(() {
      _isLoading.value = true;
      _hasError.value = false;
    });

    try {
      final summary = await nutritionRepository.getDailySummary(
        _selectedDateStr.value,
      );
      runInAction(() {
        _dailySummary.value = summary;
      });
    } catch (_) {
      runInAction(() {
        _hasError.value = true;
      });
    } finally {
      runInAction(() => _isLoading.value = false);
    }
  }

  Future<void> addFood({
    required String mealType,
    required String foodName,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final item = NutritionLogItem(
      id: const Uuid().v4(),
      dateStr: _selectedDateStr.value,
      mealType: mealType,
      foodName: foodName,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      timestamp: DateTime.now(),
    );

    await nutritionRepository.addFoodEntry(item);
    await loadDailySummary();
  }

  Future<void> deleteFood(String id) async {
    await nutritionRepository.deleteFoodEntry(id);
    await loadDailySummary();
  }

  Future<void> logWater(int amountMl) async {
    final item = HydrationLogItem(
      id: const Uuid().v4(),
      dateStr: _selectedDateStr.value,
      amountMl: amountMl,
      timestamp: DateTime.now(),
    );

    await nutritionRepository.logHydration(item);
    await loadDailySummary();
  }

  Future<void> resetHydration() async {
    await nutritionRepository.resetDayHydration(_selectedDateStr.value);
    await loadDailySummary();
  }
}
