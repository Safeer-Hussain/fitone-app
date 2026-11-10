import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/workout_repository.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final Dio dio;

  WorkoutRepositoryImpl({required this.dio});

  @override
  Future<List<Exercise>> getExercises({
    String? bodyPart,
    String? equipment,
    String? search,
    int page = 1,
    int limit = 60,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/exercises',
        queryParameters: {
          if (bodyPart != null && bodyPart != 'All') 'bodyPart': bodyPart,
          if (equipment != null && equipment != 'All') 'equipment': equipment,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final list = (response.data['data'] as List<dynamic>)
            .map((e) => Exercise.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        return list;
      }
    } catch (_) {
      // Offline fallback: query local SQLite database directly
    }

    final db = await AppDatabase.instance.database;
    String where = '';
    List<dynamic> args = [];

    if (bodyPart != null && bodyPart.isNotEmpty && bodyPart != 'All') {
      where += 'body_part = ?';
      args.add(bodyPart);
    }
    if (equipment != null && equipment.isNotEmpty && equipment != 'All') {
      if (where.isNotEmpty) where += ' AND ';
      where += 'equipment = ?';
      args.add(equipment);
    }
    if (search != null && search.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += '(name LIKE ? OR target_muscles LIKE ?)';
      args.add('%$search%');
      args.add('%$search%');
    }

    final rows = await db.query(
      'exercises',
      where: where.isEmpty ? null : where,
      whereArgs: args.isEmpty ? null : args,
      limit: limit,
      offset: (page - 1) * limit,
    );

    return rows.map((e) => Exercise.fromMap(e)).toList();
  }

  @override
  Future<Exercise?> getExerciseById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return Exercise.fromMap(rows.first);
    }
    return null;
  }

  @override
  Future<List<WorkoutPlan>> getWorkoutPlans() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('workout_plans');
    return rows.map((e) => WorkoutPlan.fromMap(e)).toList();
  }

  @override
  Future<void> saveWorkoutPlan(WorkoutPlan plan) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'workout_plans',
      plan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<WorkoutSession>> getPastWorkouts() async {
    final db = await AppDatabase.instance.database;
    final workoutRows = await db.query('workouts', orderBy: 'start_time DESC');

    List<WorkoutSession> sessions = [];
    for (final w in workoutRows) {
      final setRows = await db.query(
        'workout_sets',
        where: 'workout_id = ?',
        whereArgs: [w['id']],
        orderBy: 'set_number ASC',
      );
      final sets = setRows.map((s) => WorkoutSet.fromMap(s)).toList();
      sessions.add(WorkoutSession.fromMap(w, sets));
    }
    return sessions;
  }

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.insert(
        'workouts',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final set in session.sets) {
        await txn.insert(
          'workout_sets',
          set.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
