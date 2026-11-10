import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/entities/nutrition_day.dart';
import '../../domain/repositories/nutrition_repository.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  final Dio dio;

  NutritionRepositoryImpl({required this.dio});

  @override
  Future<DailyNutritionSummary> getDailySummary(String dateStr) async {
    final db = await AppDatabase.instance.database;

    final mealRows = await db.query(
      'nutrition_logs',
      where: 'date_str = ?',
      whereArgs: [dateStr],
      orderBy: 'timestamp ASC',
    );
    final meals = mealRows.map((e) => NutritionLogItem.fromMap(e)).toList();

    final waterRows = await db.query(
      'hydration_logs',
      where: 'date_str = ?',
      whereArgs: [dateStr],
      orderBy: 'timestamp ASC',
    );
    final water = waterRows.map((e) => HydrationLogItem.fromMap(e)).toList();

    return DailyNutritionSummary(
      dateStr: dateStr,
      mealItems: meals,
      waterItems: water,
    );
  }

  @override
  Future<void> addFoodEntry(NutritionLogItem item) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'nutrition_logs',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteFoodEntry(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('nutrition_logs', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> logHydration(HydrationLogItem item) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'hydration_logs',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> resetDayHydration(String dateStr) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'hydration_logs',
      where: 'date_str = ?',
      whereArgs: [dateStr],
    );
  }
}
