import 'dart:convert';

class PostComment {
  final String author;
  final String text;

  const PostComment({required this.author, required this.text});

  factory PostComment.fromMap(Map<String, dynamic> map) {
    return PostComment(
      author: map['author'] as String,
      text: map['text'] as String,
    );
  }

  Map<String, dynamic> toMap() => {'author': author, 'text': text};
}

class SocialPost {
  final String id;
  final String userName;
  final String userHandle;
  final String avatarInitials;
  final String postType;
  final String title;
  final String description;
  final Map<String, dynamic> metrics;
  int likesCount;
  bool isLiked;
  final List<PostComment> comments;
  final DateTime timestamp;

  SocialPost({
    required this.id,
    required this.userName,
    required this.userHandle,
    required this.avatarInitials,
    required this.postType,
    required this.title,
    required this.description,
    required this.metrics,
    required this.likesCount,
    required this.isLiked,
    required this.comments,
    required this.timestamp,
  });

  SocialPost copyWith({
    String? id,
    String? userName,
    String? userHandle,
    String? avatarInitials,
    String? postType,
    String? title,
    String? description,
    Map<String, dynamic>? metrics,
    int? likesCount,
    bool? isLiked,
    List<PostComment>? comments,
    DateTime? timestamp,
  }) {
    return SocialPost(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userHandle: userHandle ?? this.userHandle,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      postType: postType ?? this.postType,
      title: title ?? this.title,
      description: description ?? this.description,
      metrics: metrics ?? this.metrics,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory SocialPost.fromMap(Map<String, dynamic> map) {
    final rawMetrics =
        jsonDecode(map['metrics_json'] as String) as Map<String, dynamic>;
    final rawComments =
        jsonDecode(map['comments_json'] as String) as List<dynamic>;
    final comments = rawComments
        .map((e) => PostComment.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return SocialPost(
      id: map['id'] as String,
      userName: map['user_name'] as String,
      userHandle: map['user_handle'] as String,
      avatarInitials: map['avatar_initials'] as String,
      postType: map['post_type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      metrics: rawMetrics,
      likesCount: (map['likes_count'] as num).toInt(),
      isLiked: (map['is_liked'] as int) == 1,
      comments: comments,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_name': userName,
      'user_handle': userHandle,
      'avatar_initials': avatarInitials,
      'post_type': postType,
      'title': title,
      'description': description,
      'metrics_json': jsonEncode(metrics),
      'likes_count': likesCount,
      'is_liked': isLiked ? 1 : 0,
      'comments_json': jsonEncode(comments.map((c) => c.toMap()).toList()),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
