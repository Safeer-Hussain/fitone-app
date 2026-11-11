import 'package:flutter_test/flutter_test.dart';
import 'package:fitone/domain/entities/exercise.dart';
import 'package:fitone/domain/entities/superset_config.dart';
import 'package:fitone/domain/repositories/workout_repository.dart';
import 'package:fitone/presentation/exercise_workout/stores/workout_logger_store.dart';

class _FakeWorkoutRepository implements WorkoutRepository {
  WorkoutSession? lastSavedSession;

  @override
  Future<List<Exercise>> getExercises({
    String? bodyPart,
    String? equipment,
    String? search,
    int page = 1,
    int limit = 60,
  }) async => [];

  @override
  Future<Exercise?> getExerciseById(String id) async => null;

  @override
  Future<List<WorkoutPlan>> getWorkoutPlans() async => [];

  @override
  Future<void> saveWorkoutPlan(WorkoutPlan plan) async {}

  @override
  Future<List<WorkoutSession>> getPastWorkouts() async => [];

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    lastSavedSession = session;
  }
}

void main() {
  group('Superset & Drop Set Configurations Unit Tests', () {
    test('SupersetPairConfig correctly stores properties and defaults', () {
      const config = SupersetPairConfig(
        primaryExerciseId: 'ex_bench',
        primaryWeight: 100.0,
        primaryReps: 8,
        secondaryExerciseId: 'ex_row',
        secondaryWeight: 80.0,
        secondaryReps: 10,
      );

      expect(config.primaryExerciseId, 'ex_bench');
      expect(config.primaryWeight, 100.0);
      expect(config.primaryReps, 8);
      expect(config.secondaryExerciseId, 'ex_row');
      expect(config.secondaryWeight, 80.0);
      expect(config.secondaryReps, 10);
      expect(config.transitionRestSeconds, 10);
      expect(config.roundRestSeconds, 90);
      expect(config.rpe, 8.0);
    });

    test(
      'DropSetSequenceConfig.fromPercentageDrops generates accurate stages',
      () {
        final config = DropSetSequenceConfig.fromPercentageDrops(
          exerciseId: 'ex_press',
          startingWeight: 100.0,
          startingReps: 8,
          stageCount: 3,
          dropPercentPerStage: 20.0,
          intraDropRestSeconds: 5,
          postDropRestSeconds: 90,
        );

        expect(config.exerciseId, 'ex_press');
        expect(config.stages.length, 3);
        expect(config.intraDropRestSeconds, 5);
        expect(config.postDropRestSeconds, 90);

        // Stage 1: Starting load
        expect(config.stages[0].stageNumber, 1);
        expect(config.stages[0].weight, 100.0);
        expect(config.stages[0].reps, 8);
        expect(config.stages[0].dropPercentage, 0.0);

        // Stage 2: -20% -> 80.0kg
        expect(config.stages[1].stageNumber, 2);
        expect(config.stages[1].weight, 80.0);
        expect(config.stages[1].dropPercentage, 20.0);

        // Stage 3: -20% of 80 -> 64.0kg
        expect(config.stages[2].stageNumber, 3);
        expect(config.stages[2].weight, 64.0);
        expect(config.stages[2].dropPercentage, 40.0);
      },
    );

    test(
      'WorkoutSet serialization preserves SetType, linkId, and tagLabel',
      () {
        final original = WorkoutSet(
          id: 'ws_01',
          workoutId: 'w_01',
          exerciseId: 'ex_curls',
          setNumber: 1,
          weightKg: 20.0,
          reps: 12,
          rpe: 8.5,
          isCompleted: true,
          timestamp: DateTime.now(),
          setType: SetType.superset,
          linkId: 'link_pair_123',
          subStage: 0,
          tagLabel: 'SUPERSET 1A',
        );

        final map = original.toMap();
        expect(map['set_type'], 'superset');
        expect(map['link_id'], 'link_pair_123');
        expect(map['sub_stage'], 0);
        expect(map['tag_label'], 'SUPERSET 1A');

        final deserialized = WorkoutSet.fromMap(map);
        expect(deserialized.id, original.id);
        expect(deserialized.setType, SetType.superset);
        expect(deserialized.linkId, 'link_pair_123');
        expect(deserialized.subStage, 0);
        expect(deserialized.tagLabel, 'SUPERSET 1A');
      },
    );
  });

  group('WorkoutLoggerStore Superset & Drop Set Workflow Tests', () {
    late WorkoutLoggerStore store;
    late _FakeWorkoutRepository repo;

    setUp(() {
      repo = _FakeWorkoutRepository();
      store = WorkoutLoggerStore(workoutRepository: repo);
    });

    tearDown(() {
      store.stopRestTimer();
    });

    test('addSupersetPair logs two linked sets with correct metadata', () {
      store.startWorkout(title: 'Upper Strength');

      const config = SupersetPairConfig(
        primaryExerciseId: 'ex_bench',
        primaryWeight: 90.0,
        primaryReps: 8,
        secondaryExerciseId: 'ex_row',
        secondaryWeight: 75.0,
        secondaryReps: 10,
      );

      store.addSupersetPair(config);

      final session = store.activeSession;
      expect(session, isNotNull);
      expect(session!.sets.length, 2);

      final set1 = session.sets[0];
      final set2 = session.sets[1];

      expect(set1.exerciseId, 'ex_bench');
      expect(set1.weightKg, 90.0);
      expect(set1.reps, 8);
      expect(set1.setType, SetType.superset);
      expect(set1.subStage, 0);
      expect(set1.tagLabel, 'Superset A');
      expect(set1.linkId, isNotNull);

      expect(set2.exerciseId, 'ex_row');
      expect(set2.weightKg, 75.0);
      expect(set2.reps, 10);
      expect(set2.setType, SetType.superset);
      expect(set2.subStage, 1);
      expect(set2.tagLabel, 'Superset B');
      expect(set2.linkId, set1.linkId);
    });

    test('addDropSetSequence logs multi-stage drop sequence with correct progression', () {
      store.startWorkout(title: 'Shoulder Hypertrophy');

      final config = DropSetSequenceConfig.fromPercentageDrops(
        exerciseId: 'ex_lateral_raise',
        startingWeight: 15.0,
        startingReps: 10,
        stageCount: 3,
        dropPercentPerStage: 20.0,
      );

      store.addDropSetSequence(config);

      final session = store.activeSession;
      expect(session, isNotNull);
      expect(session!.sets.length, 3);

      final stage1 = session.sets[0];
      final stage2 = session.sets[1];
      final stage3 = session.sets[2];

      expect(stage1.setType, SetType.dropSet);
      expect(stage1.subStage, 0);
      expect(stage1.tagLabel, 'Drop 1 (Base)');
      expect(stage1.weightKg, 15.0);

      expect(stage2.setType, SetType.dropSet);
      expect(stage2.subStage, 1);
      expect(stage2.tagLabel, 'Drop 2 (-20%)');
      expect(stage2.weightKg, 12.0);

      expect(stage3.setType, SetType.dropSet);
      expect(stage3.subStage, 2);
      expect(stage3.tagLabel, 'Drop 3 (-40%)');
      expect(stage3.weightKg, 9.5); // 12 * 0.8 = 9.6 -> rounded to 9.5

      expect(stage1.linkId, stage2.linkId);
      expect(stage2.linkId, stage3.linkId);
    });

    test('Completing superset stage 0 starts transition timer, stage 1 starts full rest', () {
      store.startWorkout();
      store.addSupersetPair(
        const SupersetPairConfig(
          primaryExerciseId: 'ex_1',
          primaryWeight: 80,
          primaryReps: 8,
          secondaryExerciseId: 'ex_2',
          secondaryWeight: 60,
          secondaryReps: 10,
        ),
      );

      // Complete primary set (stage 0) -> Transition timer starts
      store.toggleSetCompletion(0);

      expect(store.activeSession!.sets[0].isCompleted, isTrue);
      expect(store.isRestTimerRunning, isTrue);
      expect(store.isTransitionTimer, isTrue);
      expect(store.restTimeRemaining, 10);
      expect(store.transitionTargetName, 'Superset Antagonist Exercise');

      // Complete secondary set (stage 1) -> Full rest timer starts
      store.toggleSetCompletion(1);

      expect(store.activeSession!.sets[1].isCompleted, isTrue);
      expect(store.isRestTimerRunning, isTrue);
      expect(store.isTransitionTimer, isFalse);
      expect(store.restTimeRemaining, 90);
      expect(store.transitionTargetName, isNull);
    });

    test(
      'Completing drop set stages triggers intra-drop and post-drop timers',
      () {
        store.startWorkout();
        store.addDropSetSequence(
          DropSetSequenceConfig.fromPercentageDrops(
            exerciseId: 'ex_curls',
            startingWeight: 30.0,
            startingReps: 8,
            stageCount: 2,
          ),
        );

        // Complete Stage 1 -> 5s intra-drop timer
        store.toggleSetCompletion(0);

        expect(store.isRestTimerRunning, isTrue);
        expect(store.isTransitionTimer, isTrue);
        expect(store.restTimeRemaining, 5);
        expect(store.transitionTargetName, 'Drop Weight for Next Stage');

        // Complete Stage 2 (final) -> 90s full rest
        store.toggleSetCompletion(1);

        expect(store.isRestTimerRunning, isTrue);
        expect(store.isTransitionTimer, isFalse);
        expect(store.restTimeRemaining, 90);
      },
    );

    test('Unmarking set cancels active rest timer', () {
      store.startWorkout();
      store.addSet(exerciseId: 'ex_1', weight: 100, reps: 5, rpe: 8);
      // Adding set marks it completed and starts timer
      expect(store.isRestTimerRunning, isTrue);

      // Toggling it unmarks completion and stops timer
      store.toggleSetCompletion(0);
      expect(store.activeSession!.sets[0].isCompleted, isFalse);
      expect(store.isRestTimerRunning, isFalse);
      expect(store.restTimeRemaining, 0);

      // Toggling again re-marks completion and restarts timer
      store.toggleSetCompletion(0);
      expect(store.activeSession!.sets[0].isCompleted, isTrue);
      expect(store.isRestTimerRunning, isTrue);
    });
  });
}
