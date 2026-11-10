import 'package:fitone/core/di/injection.dart';
import 'package:fitone/core/theme/theme_store.dart';
import 'package:fitone/core/utils/app_feedback.dart';
import 'package:fitone/domain/entities/exercise.dart';
import 'package:fitone/domain/entities/nutrition_day.dart';
import 'package:fitone/domain/repositories/nutrition_repository.dart';
import 'package:fitone/domain/repositories/workout_repository.dart';
import 'package:fitone/presentation/exercise_workout/stores/exercise_store.dart';
import 'package:fitone/presentation/exercise_workout/stores/workout_logger_store.dart';
import 'package:fitone/presentation/exercise_workout/views/workout_logger_view.dart';
import 'package:fitone/presentation/nutrition/stores/nutrition_store.dart';
import 'package:fitone/presentation/nutrition/widgets/quick_add_food_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNutritionRepo implements NutritionRepository {
  final List<NutritionLogItem> entries = [];

  @override
  Future<void> addFoodEntry(NutritionLogItem item) async {
    entries.add(item);
  }

  @override
  Future<void> deleteFoodEntry(String id) async {
    entries.removeWhere((i) => i.id == id);
  }

  @override
  Future<DailyNutritionSummary> getDailySummary(String dateStr) async {
    return DailyNutritionSummary(
      dateStr: dateStr,
      targetCalories: 2500,
      targetProteinG: 180,
      targetCarbsG: 250,
      targetFatG: 70,
      targetWaterMl: 3000,
      mealItems: entries,
      waterItems: const [],
    );
  }

  @override
  Future<void> logHydration(HydrationLogItem item) async {}

  @override
  Future<void> resetDayHydration(String dateStr) async {}
}

class _FakeWorkoutRepo implements WorkoutRepository {
  final List<Exercise> _exercises = const [
    Exercise(
      id: 'ex_01',
      name: 'Barbell Flat Bench Press',
      bodyPart: 'Chest',
      equipment: 'Barbell',
      targetMuscles: 'Pectoralis Major',
      instructions: 'Lower bar with control.',
      difficulty: 'Intermediate',
    ),
  ];

  @override
  Future<List<Exercise>> getExercises({
    String? bodyPart,
    String? equipment,
    String? search,
    int page = 1,
    int limit = 60,
  }) async => _exercises;

  @override
  Future<Exercise?> getExerciseById(String id) async =>
      _exercises.where((e) => e.id == id).firstOrNull;

  @override
  Future<List<WorkoutPlan>> getWorkoutPlans() async => [];

  @override
  Future<void> saveWorkoutPlan(WorkoutPlan plan) async {}

  @override
  Future<List<WorkoutSession>> getPastWorkouts() async => [];

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {}
}

void main() {
  group('Strict Form Validation & Feedback Engine Tests', () {
    late _FakeNutritionRepo nutritionRepo;
    late NutritionStore nutritionStore;

    setUp(() {
      nutritionRepo = _FakeNutritionRepo();
      nutritionStore = NutritionStore(nutritionRepository: nutritionRepo);
      nutritionStore.initialize();
    });

    testWidgets(
      'QuickAddFoodDialog rejects empty food name and zero calories with inline errors',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: QuickAddFoodDialog(store: nutritionStore)),
          ),
        );

        // Tap submit with empty fields
        final submitButton = find.byKey(
          const ValueKey('add_food_submit_button'),
        );
        expect(submitButton, findsOneWidget);
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Assert inline validation error borders/messages appear
        expect(find.text('Food or item name is required.'), findsOneWidget);
        expect(
          find.text('Enter a calorie value greater than 0.'),
          findsOneWidget,
        );
        expect(nutritionRepo.entries, isEmpty);
      },
    );

    testWidgets(
      'QuickAddFoodDialog flags invalid macro inputs and logs valid meals with feedback',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: QuickAddFoodDialog(store: nutritionStore)),
          ),
        );

        final submitButton = find.byKey(
          const ValueKey('add_food_submit_button'),
        );

        // Enter food name and calories, but invalid protein
        await tester.enterText(
          find.byKey(const ValueKey('food_name_field')),
          'Ribeye Steak',
        );
        await tester.enterText(
          find.byKey(const ValueKey('calories_field')),
          '520',
        );
        await tester.enterText(
          find.byKey(const ValueKey('protein_field')),
          '-15',
        );
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(find.text('Invalid protein value'), findsOneWidget);
        expect(nutritionRepo.entries, isEmpty);

        // Correct protein and submit
        await tester.enterText(
          find.byKey(const ValueKey('protein_field')),
          '48',
        );
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Verify entry logged and success SnackBar displayed
        expect(nutritionRepo.entries.length, equals(1));
        expect(nutritionRepo.entries.first.foodName, equals('Ribeye Steak'));
        expect(
          find.text('Logged Ribeye Steak (+520 kcal) to Breakfast'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'WorkoutLoggerView validates reps and weight and confirms set recording',
      (tester) async {
        final fakeWorkout = _FakeWorkoutRepo();

        if (!sl.isRegistered<ThemeStore>()) {
          sl.registerSingleton<ThemeStore>(ThemeStore());
        }
        if (!sl.isRegistered<WorkoutLoggerStore>()) {
          sl.registerSingleton<WorkoutLoggerStore>(
            WorkoutLoggerStore(workoutRepository: fakeWorkout),
          );
        }
        addTearDown(() => sl<WorkoutLoggerStore>().stopRestTimer());
        if (!sl.isRegistered<ExerciseStore>()) {
          final exStore = ExerciseStore(workoutRepository: fakeWorkout);
          exStore.initialize();
          sl.registerSingleton<ExerciseStore>(exStore);
        }

        await tester.pumpWidget(const MaterialApp(home: WorkoutLoggerView()));
        await tester.pumpAndSettle();

        final logSetButton = find.byKey(
          const ValueKey('workout_log_set_button'),
        );

        // Clear reps to test invalid input
        await tester.enterText(
          find.byKey(const ValueKey('workout_reps_field')),
          '0',
        );
        await tester.ensureVisible(logSetButton);
        await tester.tap(logSetButton);
        await tester.pumpAndSettle();
        expect(find.text('Reps must be at least 1.'), findsOneWidget);

        // Clear weight to negative value
        await tester.enterText(
          find.byKey(const ValueKey('workout_weight_field')),
          '-20',
        );
        await tester.ensureVisible(logSetButton);
        await tester.tap(logSetButton);
        await tester.pumpAndSettle();
        expect(find.text('Weight cannot be negative.'), findsOneWidget);

        // Supply valid inputs and submit
        await tester.enterText(
          find.byKey(const ValueKey('workout_weight_field')),
          '100.0',
        );
        await tester.enterText(
          find.byKey(const ValueKey('workout_reps_field')),
          '5',
        );
        await tester.ensureVisible(logSetButton);
        await tester.tap(logSetButton);
        await tester.pumpAndSettle();

        expect(find.text('Set recorded: 100.0kg x 5 reps'), findsOneWidget);

        sl<WorkoutLoggerStore>().stopRestTimer();
        await tester.pump();
      },
    );

    testWidgets(
      'AppFeedback displays all 4 semantic toast notifications with actions',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => AppFeedback.showSuccess(
                          ctx,
                          'Success event triggered',
                        ),
                        child: const Text('Success'),
                      ),
                      ElevatedButton(
                        onPressed: () => AppFeedback.showWarning(
                          ctx,
                          'Warning event triggered',
                        ),
                        child: const Text('Warning'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            AppFeedback.showError(ctx, 'Error event triggered'),
                        child: const Text('Error'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            AppFeedback.showInfo(ctx, 'Info event triggered'),
                        child: const Text('Info'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Test showSuccess
        await tester.tap(find.text('Success'));
        await tester.pumpAndSettle();
        expect(find.text('Success event triggered'), findsOneWidget);

        // Test showWarning
        await tester.tap(find.text('Warning'));
        await tester.pumpAndSettle();
        expect(find.text('Warning event triggered'), findsOneWidget);

        // Test showError
        await tester.tap(find.text('Error'));
        await tester.pumpAndSettle();
        expect(find.text('Error event triggered'), findsOneWidget);

        // Test showInfo
        await tester.tap(find.text('Info'));
        await tester.pumpAndSettle();
        expect(find.text('Info event triggered'), findsOneWidget);
      },
    );
  });
}
