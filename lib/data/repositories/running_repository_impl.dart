import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/entities/run_record.dart';
import '../../domain/repositories/running_repository.dart';

class RunningRepositoryImpl implements RunningRepository {
  final Dio dio;

  RunningRepositoryImpl({required this.dio});

  @override
  Future<List<RunRecord>> getRunHistory() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('running_routes', orderBy: 'start_time DESC');
    return rows.map((e) => RunRecord.fromMap(e)).toList();
  }

  @override
  Future<void> saveRunRecord(RunRecord run) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'running_routes',
      run.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<RunRecord?> getRunById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'running_routes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return RunRecord.fromMap(rows.first);
    }
    return null;
  }
}
