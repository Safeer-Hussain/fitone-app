import 'dart:convert';

class Exercise {
  final String id;
  final String name;
  final String bodyPart;
  final String equipment;
  final String targetMuscles;
  final String instructions;
  final String difficulty;

  const Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.targetMuscles,
    required this.instructions,
    required this.difficulty,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      bodyPart: map['body_part'] as String,
      equipment: map['equipment'] as String,
      targetMuscles: map['target_muscles'] as String,
      instructions: map['instructions'] as String,
      difficulty: map['difficulty'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'body_part': bodyPart,
      'equipment': equipment,
      'target_muscles': targetMuscles,
      'instructions': instructions,
      'difficulty': difficulty,
    };
  }
}

class WorkoutSet {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int setNumber;
  double weightKg;
  int reps;
  double rpe;
  bool isCompleted;
  final DateTime timestamp;

  WorkoutSet({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.rpe,
    required this.isCompleted,
    required this.timestamp,
  });

  double get oneRepMaxEpley {
    if (reps <= 1) return weightKg;
    return weightKg * (1.0 + reps / 30.0);
  }

  double get oneRepMaxBrzycki {
    if (reps >= 37) return weightKg;
    return weightKg / (1.0278 - (0.0278 * reps));
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as String,
      workoutId: map['workout_id'] as String,
      exerciseId: map['exercise_id'] as String,
      setNumber: (map['set_number'] as num).toInt(),
      weightKg: (map['weight_kg'] as num).toDouble(),
      reps: (map['reps'] as num).toInt(),
      rpe: (map['rpe'] as num).toDouble(),
      isCompleted: (map['is_completed'] as int) == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'weight_kg': weightKg,
      'reps': reps,
      'rpe': rpe,
      'is_completed': isCompleted ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class WorkoutSession {
  final String id;
  final String title;
  final DateTime startTime;
  DateTime? endTime;
  double totalVolumeKg;
  int completedSets;
  String? notes;
  final List<WorkoutSet> sets;

  WorkoutSession({
    required this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    required this.totalVolumeKg,
    required this.completedSets,
    this.notes,
    required this.sets,
  });

  factory WorkoutSession.fromMap(
    Map<String, dynamic> map,
    List<WorkoutSet> sets,
  ) {
    return WorkoutSession(
      id: map['id'] as String,
      title: map['title'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        (map['start_time'] as num).toInt(),
      ),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['end_time'] as num).toInt(),
            )
          : null,
      totalVolumeKg: (map['total_volume_kg'] as num).toDouble(),
      completedSets: (map['completed_sets'] as num).toInt(),
      notes: map['notes'] as String?,
      sets: sets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'total_volume_kg': totalVolumeKg,
      'completed_sets': completedSets,
      'notes': notes,
    };
  }
}

class WorkoutPlan {
  final String id;
  final String title;
  final String description;
  final int daysPerWeek;
  final List<Map<String, dynamic>> schedule;

  const WorkoutPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.daysPerWeek,
    required this.schedule,
  });

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    final raw = jsonDecode(map['schedule_json'] as String) as List<dynamic>;
    final schedule = raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return WorkoutPlan(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      daysPerWeek: (map['days_per_week'] as num).toInt(),
      schedule: schedule,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'days_per_week': daysPerWeek,
      'schedule_json': jsonEncode(schedule),
    };
  }
}
