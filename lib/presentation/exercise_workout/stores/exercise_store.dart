import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../domain/entities/exercise.dart';
import '../../../domain/repositories/workout_repository.dart';

class ExerciseStore {
  final WorkoutRepository workoutRepository;

  ExerciseStore({required this.workoutRepository});

  final _isLoading = Observable<bool>(false);
  bool get isLoading => _isLoading.value;

  final _hasError = Observable<bool>(false);
  bool get hasError => _hasError.value;

  final _errorMessage = Observable<String>('');
  String get errorMessage => _errorMessage.value;

  final _exercises = ObservableList<Exercise>();
  List<Exercise> get exercises => _exercises;

  final _workoutPlans = ObservableList<WorkoutPlan>();
  List<WorkoutPlan> get workoutPlans => _workoutPlans;

  final _selectedBodyPart = Observable<String>('All');
  String get selectedBodyPart => _selectedBodyPart.value;

  final _selectedEquipment = Observable<String>('All');
  String get selectedEquipment => _selectedEquipment.value;

  final _searchQuery = Observable<String>('');
  String get searchQuery => _searchQuery.value;

  Timer? _debounceTimer;

  final List<String> bodyParts = const [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Full Body',
  ];

  final List<String> equipmentList = const [
    'All',
    'Barbell',
    'Dumbbells',
    'Gym Machines',
    'Cables',
    'Kettlebells',
    'Bodyweight',
  ];

  Future<void> initialize() async {
    await loadExercises();
    await loadWorkoutPlans();
  }

  Future<void> loadExercises() async {
    runInAction(() {
      _isLoading.value = true;
      _hasError.value = false;
      _errorMessage.value = '';
    });

    try {
      final items = await workoutRepository.getExercises(
        bodyPart: _selectedBodyPart.value,
        equipment: _selectedEquipment.value,
        search: _searchQuery.value,
        limit: 100,
      );
      runInAction(() {
        _exercises.clear();
        _exercises.addAll(items);
      });
    } catch (e) {
      runInAction(() {
        _hasError.value = true;
        _errorMessage.value = e.toString();
      });
    } finally {
      runInAction(() => _isLoading.value = false);
    }
  }

  void setBodyPart(String bodyPart) {
    if (_selectedBodyPart.value == bodyPart) return;
    runInAction(() => _selectedBodyPart.value = bodyPart);
    loadExercises();
  }

  void setEquipment(String equipment) {
    if (_selectedEquipment.value == equipment) return;
    runInAction(() => _selectedEquipment.value = equipment);
    loadExercises();
  }

  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      runInAction(() => _searchQuery.value = query);
      loadExercises();
    });
  }

  Future<void> loadWorkoutPlans() async {
    try {
      final plans = await workoutRepository.getWorkoutPlans();
      runInAction(() {
        _workoutPlans.clear();
        _workoutPlans.addAll(plans);
      });
    } catch (_) {}
  }

  Future<void> saveNewWorkoutPlan(WorkoutPlan plan) async {
    await workoutRepository.saveWorkoutPlan(plan);
    await loadWorkoutPlans();
  }
}
