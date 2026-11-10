import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/exercise.dart';
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
    });

    startRestTimer(90);
  }

  void toggleSetCompletion(int index) {
    if (_activeSession.value == null ||
        index >= _activeSession.value!.sets.length) {
      return;
    }

    runInAction(() {
      final set = _activeSession.value!.sets[index];
      set.isCompleted = !set.isCompleted;
      _recalculateSessionTotals();
    });
  }

  void removeSet(int index) {
    if (_activeSession.value == null ||
        index >= _activeSession.value!.sets.length) {
      return;
    }

    runInAction(() {
      _activeSession.value!.sets.removeAt(index);
      _recalculateSessionTotals();
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
    });
  }

  void toggleUnit() {
    runInAction(() {
      _unit.value = _unit.value == 'kg' ? 'lbs' : 'kg';
    });
  }
}
