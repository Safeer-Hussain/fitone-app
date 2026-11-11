import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/superset_config.dart';
import '../../../domain/repositories/workout_repository.dart';

class WorkoutLoggerStore {
  final WorkoutRepository workoutRepository;

  WorkoutLoggerStore({required this.workoutRepository});

  final _activeSession = Observable<WorkoutSession?>(null);
  WorkoutSession? get activeSession => _activeSession.value;

  final _unit = Observable<String>('kg');
  String get unit => _unit.value;

  final _isRestTimerRunning = Observable<bool>(false);
  bool get isRestTimerRunning => _isRestTimerRunning.value;

  final _isTransitionTimer = Observable<bool>(false);
  bool get isTransitionTimer => _isTransitionTimer.value;

  final _transitionTargetName = Observable<String?>(null);
  String? get transitionTargetName => _transitionTargetName.value;

  final _restTimeRemaining = Observable<int>(0);
  int get restTimeRemaining => _restTimeRemaining.value;

  final _restTimeTotal = Observable<int>(90);
  int get restTimeTotal => _restTimeTotal.value;

  Timer? _restCountdownTimer;

  bool get isSessionActive => _activeSession.value != null;

  void startWorkout({String title = 'Chest & Triceps Hypertrophy'}) {
    final session = WorkoutSession(
      id: const Uuid().v4(),
      title: title,
      startTime: DateTime.now(),
      totalVolumeKg: 0.0,
      completedSets: 0,
      sets: [],
    );
    runInAction(() {
      _activeSession.value = session;
    });
  }

  void addSet({
    required String exerciseId,
    required double weight,
    required int reps,
    required double rpe,
  }) {
    if (_activeSession.value == null) {
      startWorkout();
    }

    final currentSets = _activeSession.value!.sets;
    final setNumber =
        currentSets.where((s) => s.exerciseId == exerciseId).length + 1;

    final newSet = WorkoutSet(
      id: const Uuid().v4(),
      workoutId: _activeSession.value!.id,
      exerciseId: exerciseId,
      setNumber: setNumber,
      weightKg: _unit.value == 'lbs' ? weight * 0.453592 : weight,
      reps: reps,
      rpe: rpe,
      isCompleted: true,
      timestamp: DateTime.now(),
    );

    runInAction(() {
      currentSets.add(newSet);
      _recalculateSessionTotals();
      _activeSession.reportChanged();
    });

    startRestTimer(90);
  }

  void addSupersetPair(SupersetPairConfig config) {
    if (_activeSession.value == null) {
      startWorkout();
    }

    final currentSets = _activeSession.value!.sets;
    final linkId =
        'ss_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 6)}';
    final tagA = config.customTag ?? 'Superset A';
    final tagB = config.customTag != null
        ? '${config.customTag} (Pair)'
        : 'Superset B';

    final setNumberA =
        currentSets
            .where((s) => s.exerciseId == config.primaryExerciseId)
            .length +
        1;
    final setNumberB =
        currentSets
            .where((s) => s.exerciseId == config.secondaryExerciseId)
            .length +
        1;

    final primaryWeightKg = _unit.value == 'lbs'
        ? config.primaryWeight * 0.453592
        : config.primaryWeight;
    final secondaryWeightKg = _unit.value == 'lbs'
        ? config.secondaryWeight * 0.453592
        : config.secondaryWeight;

    final setA = WorkoutSet(
      id: const Uuid().v4(),
      workoutId: _activeSession.value!.id,
      exerciseId: config.primaryExerciseId,
      setNumber: setNumberA,
      weightKg: primaryWeightKg,
      reps: config.primaryReps,
      rpe: config.rpe,
      isCompleted: false,
      timestamp: DateTime.now(),
      setType: SetType.superset,
      linkId: linkId,
      subStage: 0,
      tagLabel: tagA,
    );

    final setB = WorkoutSet(
      id: const Uuid().v4(),
      workoutId: _activeSession.value!.id,
      exerciseId: config.secondaryExerciseId,
      setNumber: setNumberB,
      weightKg: secondaryWeightKg,
      reps: config.secondaryReps,
      rpe: config.rpe,
      isCompleted: false,
      timestamp: DateTime.now().add(const Duration(seconds: 1)),
      setType: SetType.superset,
      linkId: linkId,
      subStage: 1,
      tagLabel: tagB,
    );

    runInAction(() {
      currentSets.add(setA);
      currentSets.add(setB);
      _recalculateSessionTotals();
      _activeSession.reportChanged();
    });
  }

  void addDropSetSequence(DropSetSequenceConfig config) {
    if (_activeSession.value == null) {
      startWorkout();
    }

    final currentSets = _activeSession.value!.sets;
    final linkId =
        'ds_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 6)}';
    final baseSetNumber =
        currentSets.where((s) => s.exerciseId == config.exerciseId).length + 1;

    final newSets = <WorkoutSet>[];
    for (var i = 0; i < config.stages.length; i++) {
      final stage = config.stages[i];
      final weightKg = _unit.value == 'lbs'
          ? stage.weight * 0.453592
          : stage.weight;
      final dropLabel = i == 0
          ? 'Drop 1 (Base)'
          : 'Drop ${i + 1} (-${stage.dropPercentage.toStringAsFixed(0)}%)';

      newSets.add(
        WorkoutSet(
          id: const Uuid().v4(),
          workoutId: _activeSession.value!.id,
          exerciseId: config.exerciseId,
          setNumber: baseSetNumber + i,
          weightKg: weightKg,
          reps: stage.reps,
          rpe: config.rpe,
          isCompleted: false,
          timestamp: DateTime.now().add(Duration(seconds: i)),
          setType: SetType.dropSet,
          linkId: linkId,
          subStage: i,
          tagLabel: dropLabel,
        ),
      );
    }

    runInAction(() {
      currentSets.addAll(newSets);
      _recalculateSessionTotals();
      _activeSession.reportChanged();
    });
  }

  void startTransitionTimer({
    required int seconds,
    required String targetName,
  }) {
    _restCountdownTimer?.cancel();
    runInAction(() {
      _restTimeTotal.value = seconds;
      _restTimeRemaining.value = seconds;
      _isTransitionTimer.value = true;
      _transitionTargetName.value = targetName;
      _isRestTimerRunning.value = true;
    });

    _restCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining.value <= 1) {
        stopRestTimer();
      } else {
        runInAction(() {
          _restTimeRemaining.value--;
        });
      }
    });
  }

  void toggleSetCompletion(int index) {
    if (_activeSession.value == null ||
        index >= _activeSession.value!.sets.length) {
      return;
    }

    final set = _activeSession.value!.sets[index];
    final wasCompleted = set.isCompleted;

    runInAction(() {
      set.isCompleted = !wasCompleted;
      _recalculateSessionTotals();
      _activeSession.reportChanged();
    });

    // If marked completed, handle automated back-to-back timer tracking
    if (!wasCompleted) {
      if (set.setType == SetType.superset) {
        if (set.subStage == 0) {
          startTransitionTimer(
            seconds: 10,
            targetName: 'Superset Antagonist Exercise',
          );
        } else {
          startRestTimer(90);
        }
      } else if (set.setType == SetType.dropSet) {
        final allInGroup = _activeSession.value!.sets
            .where((s) => s.linkId == set.linkId)
            .toList();
        final isLast = set.subStage >= allInGroup.length - 1;
        if (!isLast) {
          startTransitionTimer(
            seconds: 5,
            targetName: 'Drop Weight for Next Stage',
          );
        } else {
          startRestTimer(90);
        }
      } else {
        startRestTimer(90);
      }
    } else {
      stopRestTimer();
    }
  }

  void removeSet(int index) {
    if (_activeSession.value == null ||
        index >= _activeSession.value!.sets.length) {
      return;
    }

    runInAction(() {
      _activeSession.value!.sets.removeAt(index);
      _recalculateSessionTotals();
      _activeSession.reportChanged();
    });
  }

  void _recalculateSessionTotals() {
    if (_activeSession.value == null) return;
    double volume = 0;
    int completed = 0;

    for (final s in _activeSession.value!.sets) {
      if (s.isCompleted) {
        volume += (s.weightKg * s.reps);
        completed++;
      }
    }

    _activeSession.value!.totalVolumeKg = volume;
    _activeSession.value!.completedSets = completed;
  }

  Future<void> finishWorkout({String? notes}) async {
    if (_activeSession.value == null) return;

    final session = _activeSession.value!;
    session.endTime = DateTime.now();
    session.notes = notes;

    await workoutRepository.saveWorkoutSession(session);

    runInAction(() {
      _activeSession.value = null;
    });
    stopRestTimer();
  }

  void cancelWorkout() {
    runInAction(() {
      _activeSession.value = null;
    });
    stopRestTimer();
  }

  void startRestTimer(int seconds) {
    _restCountdownTimer?.cancel();
    runInAction(() {
      _restTimeTotal.value = seconds;
      _restTimeRemaining.value = seconds;
      _isRestTimerRunning.value = true;
      _isTransitionTimer.value = false;
      _transitionTargetName.value = null;
    });

    _restCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining.value <= 1) {
        stopRestTimer();
      } else {
        runInAction(() {
          _restTimeRemaining.value--;
        });
      }
    });
  }

  void stopRestTimer() {
    _restCountdownTimer?.cancel();
    _restCountdownTimer = null;
    runInAction(() {
      _isRestTimerRunning.value = false;
      _restTimeRemaining.value = 0;
      _isTransitionTimer.value = false;
      _transitionTargetName.value = null;
    });
  }

  void toggleUnit() {
    runInAction(() {
      _unit.value = _unit.value == 'kg' ? 'lbs' : 'kg';
    });
  }
}
