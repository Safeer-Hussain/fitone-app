import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitone/core/di/injection.dart';
import 'package:fitone/core/theme/theme_store.dart';
import 'package:fitone/domain/entities/exercise.dart';
import 'package:fitone/domain/repositories/workout_repository.dart';
import 'package:fitone/presentation/exercise_workout/stores/exercise_store.dart';
import 'package:fitone/presentation/exercise_workout/stores/workout_logger_store.dart';
import 'package:fitone/presentation/exercise_workout/views/exercise_detail_view.dart';
import 'package:fitone/presentation/exercise_workout/views/workout_logger_view.dart';
import 'package:fitone/presentation/exercise_workout/widgets/barbell_plate_calculator_sheet.dart';

class _MockWorkoutRepository implements WorkoutRepository {
  final List<Exercise> exercises = const [
    Exercise(
      id: 'ex_01',
      name: 'Barbell Flat Bench Press',
      bodyPart: 'Chest',
      equipment: 'Barbell',
      targetMuscles: 'Pectoralis Major',
      instructions: 'Retract scapulae and lower bar smoothly to sternum.',
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
  }) async => exercises;

  @override
  Future<Exercise?> getExerciseById(String id) async =>
      exercises.where((e) => e.id == id).firstOrNull;

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
  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<ThemeStore>(() => ThemeStore());
    sl.registerLazySingleton<WorkoutRepository>(() => _MockWorkoutRepository());
    sl.registerLazySingleton<WorkoutLoggerStore>(
      () => WorkoutLoggerStore(workoutRepository: sl<WorkoutRepository>()),
    );
    sl.registerLazySingleton<ExerciseStore>(
      () => ExerciseStore(workoutRepository: sl<WorkoutRepository>()),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: child),
    );
  }

  void setupPortrait(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('BarbellPlateCalculatorSheet Widget Tests', () {
    testWidgets(
      'Renders sheet with 100kg default load and visual barbell plates',
      (tester) async {
        setupPortrait(tester);
        await tester.pumpWidget(
          createTestWidget(
            const BarbellPlateCalculatorSheet(initialWeight: 100.0, unit: 'kg'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Plate Loading Calculator'), findsOneWidget);
        expect(find.text('TARGET LOAD'), findsOneWidget);
        expect(find.text('100.0'), findsOneWidget);
        expect(find.text('KG'), findsWidgets);
        expect(find.text('40.00 kg per side'), findsOneWidget);
        expect(find.text('2 plates total'), findsOneWidget);
        expect(find.text('25 kg × 1'), findsOneWidget);
        expect(find.text('15 kg × 1'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping quick step adjustment increases weight and updates plates',
      (tester) async {
        setupPortrait(tester);
        await tester.pumpWidget(
          createTestWidget(
            const BarbellPlateCalculatorSheet(initialWeight: 100.0, unit: 'kg'),
          ),
        );
        await tester.pumpAndSettle();

        // Find +20 quick adjustment chip
        final plus20Chip = find.text('+20');
        expect(plus20Chip, findsOneWidget);
        await tester.ensureVisible(plus20Chip);
        await tester.tap(plus20Chip);
        await tester.pumpAndSettle();

        // Target should be 120.0 kg
        expect(find.text('120.0'), findsOneWidget);
        expect(find.text('50.00 kg per side'), findsOneWidget);
        expect(find.text('25 kg × 2'), findsOneWidget);
      },
    );

    testWidgets(
      'Selecting benchmark preset 140 kg updates configuration immediately',
      (tester) async {
        setupPortrait(tester);
        await tester.pumpWidget(
          createTestWidget(
            const BarbellPlateCalculatorSheet(initialWeight: 100.0, unit: 'kg'),
          ),
        );
        await tester.pumpAndSettle();

        final preset140 = find.text('140 kg');
        expect(preset140, findsOneWidget);
        await tester.ensureVisible(preset140);
        await tester.tap(preset140);
        await tester.pumpAndSettle();

        expect(find.text('140.0'), findsOneWidget);
        expect(find.text('60.00 kg per side'), findsOneWidget);
        expect(find.text('25 kg × 2'), findsOneWidget);
        expect(find.text('10 kg × 1'), findsOneWidget);
      },
    );

    testWidgets('Switching unit to LBS recalculates in imperial pounds', (
      tester,
    ) async {
      setupPortrait(tester);
      await tester.pumpWidget(
        createTestWidget(
          const BarbellPlateCalculatorSheet(initialWeight: 100.0, unit: 'kg'),
        ),
      );
      await tester.pumpAndSettle();

      final unitButton = find.widgetWithText(OutlinedButton, 'KG');
      expect(unitButton, findsOneWidget);
      await tester.tap(unitButton);
      await tester.pumpAndSettle();

      expect(find.text('LBS'), findsWidgets);
      expect(find.text('45lb Olympic'), findsOneWidget);
    });

    testWidgets(
      'Displays unachievable remainder banner on odd fractional load',
      (tester) async {
        setupPortrait(tester);
        await tester.pumpWidget(
          createTestWidget(
            const BarbellPlateCalculatorSheet(initialWeight: 61.0, unit: 'kg'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Unachievable Remainder: 1.00 kg'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Apply Weight button passes calculated load back to callback', (
      tester,
    ) async {
      setupPortrait(tester);
      double? appliedWeight;

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                BarbellPlateCalculatorSheet.show(
                  context,
                  initialWeight: 140.0,
                  unit: 'kg',
                  onWeightApplied: (w) => appliedWeight = w,
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final applyButton = find.text('Apply Weight');
      expect(applyButton, findsOneWidget);
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      expect(appliedWeight, 140.0);
    });

    testWidgets(
      'WorkoutLoggerView opens BarbellPlateCalculatorSheet via AppBar action',
      (tester) async {
        setupPortrait(tester);
        await tester.pumpWidget(createTestWidget(const WorkoutLoggerView()));
        await tester.pumpAndSettle();

        final plateBtn = find.byKey(
          const ValueKey('plate_calculator_appbar_button'),
        );
        expect(plateBtn, findsOneWidget);
        await tester.tap(plateBtn);
        await tester.pumpAndSettle();

        expect(find.text('Plate Loading Calculator'), findsOneWidget);
      },
    );

    testWidgets(
      'ExerciseDetailView opens BarbellPlateCalculatorSheet via button',
      (tester) async {
        setupPortrait(tester);
        const exercise = Exercise(
          id: 'ex_test_01',
          name: 'Barbell Back Squat',
          bodyPart: 'Legs',
          equipment: 'Barbell',
          targetMuscles: 'Quadriceps, Glutes',
          instructions: 'Descend to parallel keeping torso upright.',
          difficulty: 'Advanced',
        );

        await tester.pumpWidget(
          createTestWidget(const ExerciseDetailView(exercise: exercise)),
        );
        await tester.pumpAndSettle();

        final calcBtn = find.byKey(
          const ValueKey('open_plate_calculator_detail_button'),
        );
        expect(calcBtn, findsOneWidget);
        await tester.ensureVisible(calcBtn);
        await tester.tap(calcBtn);
        await tester.pumpAndSettle();

        expect(find.text('Plate Loading Calculator'), findsOneWidget);
      },
    );
  });
}
