import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitone/core/di/injection.dart';
import 'package:fitone/core/theme/theme_store.dart';
import 'package:fitone/domain/entities/exercise.dart';
import 'package:fitone/domain/repositories/workout_repository.dart';
import 'package:fitone/presentation/exercise_workout/stores/exercise_store.dart';
import 'package:fitone/presentation/exercise_workout/stores/workout_logger_store.dart';
import 'package:fitone/presentation/exercise_workout/views/workout_logger_view.dart';
import 'package:fitone/presentation/exercise_workout/widgets/superset_drop_set_dialog.dart';

class _MockWorkoutRepository implements WorkoutRepository {
  final List<Exercise> exercises = const [
    Exercise(
      id: 'ex_bench',
      name: 'Barbell Flat Bench Press',
      bodyPart: 'Chest',
      equipment: 'Barbell',
      targetMuscles: 'Pectoralis Major, Triceps',
      instructions: 'Lower bar smoothly to mid-chest and press up.',
      difficulty: 'Intermediate',
    ),
    Exercise(
      id: 'ex_row',
      name: 'Barbell Bent-Over Row',
      bodyPart: 'Back',
      equipment: 'Barbell',
      targetMuscles: 'Latissimus Dorsi, Rhomboids',
      instructions: 'Hinge at hips and pull bar towards lower ribcage.',
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
  late WorkoutLoggerStore loggerStore;
  late ExerciseStore exerciseStore;
  late _MockWorkoutRepository mockRepo;

  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<ThemeStore>(() => ThemeStore());
    mockRepo = _MockWorkoutRepository();
    sl.registerLazySingleton<WorkoutRepository>(() => mockRepo);
    loggerStore = WorkoutLoggerStore(workoutRepository: mockRepo);
    sl.registerLazySingleton<WorkoutLoggerStore>(() => loggerStore);
    exerciseStore = ExerciseStore(workoutRepository: mockRepo);
    sl.registerLazySingleton<ExerciseStore>(() => exerciseStore);
    await exerciseStore.loadExercises();
  });

  tearDown(() async {
    loggerStore.stopRestTimer();
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

  void setupLandscape(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('SupersetDropSetDialog & Builder Widget Tests', () {
    testWidgets(
      'Renders SupersetDropSetDialog with antagonist superset controls by default',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(
          createTestWidget(
            SupersetDropSetDialog(
              loggerStore: loggerStore,
              exercises: mockRepo.exercises,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Superset & Drop Set Builder'), findsOneWidget);
        expect(find.text('Antagonist Superset'), findsOneWidget);
        expect(find.text('Multi-Stage Drop Set'), findsOneWidget);
        expect(find.text('Exercise 1 (Agonist / Primary)'), findsOneWidget);
        expect(
          find.text('Exercise 2 (Antagonist / Secondary)'),
          findsOneWidget,
        );
        expect(find.text('Auto Transition: 10s back-to-back'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('add_superset_pair_button')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Switching to Drop Set tab displays stage progression parameters & preview',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(
          createTestWidget(
            SupersetDropSetDialog(
              loggerStore: loggerStore,
              exercises: mockRepo.exercises,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final dropTab = find.text('Multi-Stage Drop Set');
        await tester.tap(dropTab);
        await tester.pumpAndSettle();

        expect(find.text('Target Exercise & Initial Weight'), findsOneWidget);
        expect(find.text('Drop Progression Parameters'), findsOneWidget);
        expect(find.text('Sequence Preview (Back-to-Back)'), findsOneWidget);
        expect(find.text('Stage 1'), findsOneWidget);
        expect(find.text('Stage 2'), findsOneWidget);
        expect(find.text('Stage 3'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('add_drop_set_sequence_button')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Tapping Add Antagonist Superset Pair adds two linked sets with badges to session',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(
          createTestWidget(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SupersetDropSetDialog.show(
                  ctx,
                  loggerStore: loggerStore,
                  exercises: mockRepo.exercises,
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        final addBtn = find.byKey(const ValueKey('add_superset_pair_button'));
        expect(addBtn, findsOneWidget);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        // Sheet dismissed and sets added to active session
        expect(loggerStore.activeSession, isNotNull);
        expect(loggerStore.activeSession!.sets.length, 2);
        expect(loggerStore.activeSession!.sets[0].setType, SetType.superset);
        expect(loggerStore.activeSession!.sets[0].tagLabel, 'Superset A');
        expect(loggerStore.activeSession!.sets[1].setType, SetType.superset);
        expect(loggerStore.activeSession!.sets[1].tagLabel, 'Superset B');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Tapping Add Drop Set adds multi-stage sequence to active session',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(
          createTestWidget(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SupersetDropSetDialog.show(
                  ctx,
                  loggerStore: loggerStore,
                  exercises: mockRepo.exercises,
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Multi-Stage Drop Set'));
        await tester.pumpAndSettle();

        final addDropBtn = find.byKey(
          const ValueKey('add_drop_set_sequence_button'),
        );
        expect(addDropBtn, findsOneWidget);
        await tester.tap(addDropBtn);
        await tester.pumpAndSettle();

        expect(loggerStore.activeSession, isNotNull);
        expect(loggerStore.activeSession!.sets.length, 3);
        expect(loggerStore.activeSession!.sets[0].setType, SetType.dropSet);
        expect(loggerStore.activeSession!.sets[0].tagLabel, 'Drop 1 (Base)');
        expect(loggerStore.activeSession!.sets[1].tagLabel, 'Drop 2 (-20%)');
        expect(loggerStore.activeSession!.sets[2].tagLabel, 'Drop 3 (-40%)');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'WorkoutLoggerView shows Superset launcher button and displays transition timer banner on completion',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(createTestWidget(const WorkoutLoggerView()));
        await tester.pumpAndSettle();

        // Check AppBar launcher button
        final appbarLauncher = find.byKey(
          const ValueKey('workout_open_superset_builder_button'),
        );
        expect(appbarLauncher, findsOneWidget);

        // Check Inline launcher button
        final inlineLauncher = find.byKey(
          const ValueKey('workout_superset_inline_launcher'),
        );
        expect(inlineLauncher, findsOneWidget);

        // Open builder dialog via appbar launcher
        await tester.tap(appbarLauncher);
        await tester.pumpAndSettle();
        expect(find.text('Superset & Drop Set Builder'), findsOneWidget);

        // Add superset pair
        await tester.tap(
          find.byKey(const ValueKey('add_superset_pair_button')),
        );
        await tester.pumpAndSettle();

        // Verify sets appear with badges in sets list
        expect(find.text('Superset A'), findsOneWidget);
        expect(find.text('Superset B'), findsOneWidget);

        // Complete Stage 1A -> verify transition timer countdown pill appears
        final completeBtns = find.byIcon(Icons.radio_button_unchecked_rounded);
        expect(completeBtns, findsWidgets);
        await tester.tap(completeBtns.first);
        await tester.pumpAndSettle();

        expect(loggerStore.isTransitionTimer, isTrue);
        expect(
          find.textContaining('Switch: 10s • Superset Antagonist Exercise'),
          findsOneWidget,
        );
        loggerStore.stopRestTimer();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Landscape viewport (800x360) renders WorkoutLoggerView & SupersetDropSetDialog with zero overflow',
      (tester) async {
        setupLandscape(tester);

        await tester.pumpWidget(createTestWidget(const WorkoutLoggerView()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Open Superset & Drop Set Dialog in landscape
        final appbarLauncher = find.byKey(
          const ValueKey('workout_open_superset_builder_button'),
        );
        expect(appbarLauncher, findsOneWidget);
        await tester.tap(appbarLauncher);
        await tester.pumpAndSettle();

        expect(find.text('Superset & Drop Set Builder'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Switch to Drop Set tab in landscape
        await tester.tap(find.text('Multi-Stage Drop Set'));
        await tester.pumpAndSettle();

        expect(find.text('Sequence Preview (Back-to-Back)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
