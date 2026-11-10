import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/entities/social_post.dart';
import '../../domain/repositories/social_repository.dart';

class SocialRepositoryImpl implements SocialRepository {
  final Dio dio;

  SocialRepositoryImpl({required this.dio});

  @override
  Future<List<SocialPost>> getCommunityFeed() async {
    try {
      final res = await dio.get('/api/v1/social/feed');
      if (res.statusCode == 200) {
        final list = (res.data['data'] as List<dynamic>)
            .map((e) => SocialPost.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        return list;
      }
    } catch (_) {}

    final db = await AppDatabase.instance.database;
    final rows = await db.query('social_posts', orderBy: 'timestamp DESC');
    return rows.map((e) => SocialPost.fromMap(e)).toList();
  }

  @override
  Future<void> toggleLike(String postId, bool isLiked) async {
    final db = await AppDatabase.instance.database;
    final countDelta = isLiked ? 1 : -1;
    await db.rawUpdate(
      '''
      UPDATE social_posts 
      SET likes_count = MAX(0, likes_count + ?), is_liked = ?
      WHERE id = ?
    ''',
      [countDelta, isLiked ? 1 : 0, postId],
    );
  }

  @override
  Future<void> addComment(String postId, PostComment comment) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'social_posts',
      where: 'id = ?',
      whereArgs: [postId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final post = SocialPost.fromMap(rows.first);
      post.comments.add(comment);
      await db.update(
        'social_posts',
        {
          'comments_json': jsonEncode(
            post.comments.map((c) => c.toMap()).toList(),
          ),
        },
        where: 'id = ?',
        whereArgs: [postId],
      );
    }
  }

  @override
  Future<void> createPost(SocialPost post) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'social_posts',
      post.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
