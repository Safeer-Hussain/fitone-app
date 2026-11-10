import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../database/app_database.dart';
import 'network_monitor.dart';

class MockApiInterceptor extends Interceptor {
  final Random _random = Random();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final monitor = NetworkMonitor.instance;

    // Apply simulated latency (650ms to 1100ms base or custom)
    final latency = monitor.simulatedLatencyMs > 0
        ? monitor.simulatedLatencyMs + _random.nextInt(200) - 100
        : 50;
    await Future.delayed(Duration(milliseconds: max(50, latency)));

    // Forced error simulation or offline mode
    if (monitor.forceApiError || !monitor.isOnline) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: monitor.forceApiError
              ? 'Simulated Server Failure: 503 Service Unavailable'
              : 'Network Offline: Fallback to local SQL cache',
          type: DioExceptionType.connectionError,
          response: Response(
            requestOptions: options,
            statusCode: monitor.forceApiError ? 503 : 504,
            statusMessage: 'Error',
          ),
        ),
      );
    }

    try {
      final response = await _routeRequest(options);
      return handler.resolve(response);
    } catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Future<Response> _routeRequest(RequestOptions options) async {
    final db = await AppDatabase.instance.database;
    final path = options.path;

    if (path.contains('/api/v1/exercises')) {
      final query = options.queryParameters;
      final bodyPart = query['bodyPart'] as String?;
      final equipment = query['equipment'] as String?;
      final search = query['search'] as String?;
      final page = int.tryParse(query['page']?.toString() ?? '1') ?? 1;
      final limit = int.tryParse(query['limit']?.toString() ?? '20') ?? 20;

      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (bodyPart != null && bodyPart.isNotEmpty && bodyPart != 'All') {
        whereClause += 'body_part = ?';
        whereArgs.add(bodyPart);
      }

      if (equipment != null && equipment.isNotEmpty && equipment != 'All') {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'equipment = ?';
        whereArgs.add(equipment);
      }

      if (search != null && search.isNotEmpty) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += '(name LIKE ? OR target_muscles LIKE ?)';
        whereArgs.add('%$search%');
        whereArgs.add('%$search%');
      }

      final offset = (page - 1) * limit;
      final results = await db.query(
        'exercises',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        limit: limit,
        offset: offset,
      );

      final totalCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM exercises ${whereClause.isEmpty ? '' : 'WHERE $whereClause'}',
        whereArgs,
      );
      final totalCount = totalCountResult.first['count'] as int;

      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'status': 'success',
          'data': results,
          'meta': {
            'page': page,
            'limit': limit,
            'total': totalCount,
            'hasMore': (offset + limit) < totalCount,
          },
        },
      );
    }

    if (path.contains('/api/v1/social/feed')) {
      final results = await db.query('social_posts', orderBy: 'timestamp DESC');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'status': 'success', 'data': results},
      );
    }

    if (path.contains('/api/v1/social/like')) {
      final postId = options.data['postId'] as String;
      final isLiked = options.data['isLiked'] as bool;
      final countDelta = isLiked ? 1 : -1;

      await db.rawUpdate(
        '''
        UPDATE social_posts 
        SET likes_count = likes_count + ?, is_liked = ?
        WHERE id = ?
      ''',
        [countDelta, isLiked ? 1 : 0, postId],
      );

      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'status': 'success', 'postId': postId, 'isLiked': isLiked},
      );
    }

    if (path.contains('/api/v1/nutrition')) {
      final dateStr =
          options.queryParameters['date'] as String? ??
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      final results = await db.query(
        'nutrition_logs',
        where: 'date_str = ?',
        whereArgs: [dateStr],
        orderBy: 'timestamp ASC',
      );
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'status': 'success', 'data': results},
      );
    }

    if (path.contains('/api/v1/hydration')) {
      final dateStr =
          options.queryParameters['date'] as String? ??
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      final results = await db.query(
        'hydration_logs',
        where: 'date_str = ?',
        whereArgs: [dateStr],
        orderBy: 'timestamp ASC',
      );
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'status': 'success', 'data': results},
      );
    }

    if (path.contains('/api/v1/runs')) {
      final results = await db.query(
        'running_routes',
        orderBy: 'start_time DESC',
      );
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'status': 'success', 'data': results},
      );
    }

    return Response(
      requestOptions: options,
      statusCode: 200,
      data: {'status': 'success', 'message': 'Endpoint executed successfully'},
    );
  }
}
