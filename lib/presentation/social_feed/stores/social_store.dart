import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/social_post.dart';
import '../../../domain/repositories/social_repository.dart';

class SocialStore {
  final SocialRepository socialRepository;

  SocialStore({required this.socialRepository});

  final _isLoading = Observable<bool>(false);
  bool get isLoading => _isLoading.value;

  final _hasError = Observable<bool>(false);
  bool get hasError => _hasError.value;

  final _posts = ObservableList<SocialPost>();
  List<SocialPost> get posts => _posts;

  final _activeTab = Observable<int>(0); // 0 = Feed, 1 = Leaderboard
  int get activeTab => _activeTab.value;

  Future<void> initialize() async {
    await loadFeed();
  }

  void setActiveTab(int index) {
    runInAction(() => _activeTab.value = index);
  }

  Future<void> loadFeed() async {
    runInAction(() {
      _isLoading.value = true;
      _hasError.value = false;
    });

    try {
      final items = await socialRepository.getCommunityFeed();
      runInAction(() {
        _posts.clear();
        _posts.addAll(items);
      });
    } catch (_) {
      runInAction(() => _hasError.value = true);
    } finally {
      runInAction(() => _isLoading.value = false);
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final newLiked = !post.isLiked;
    final newCount = newLiked
        ? post.likesCount + 1
        : (post.likesCount > 0 ? post.likesCount - 1 : 0);

    runInAction(() {
      _posts[index] = post.copyWith(isLiked: newLiked, likesCount: newCount);
    });

    await socialRepository.toggleLike(postId, newLiked);
  }

  Future<void> addComment(String postId, String text) async {
    if (text.trim().isEmpty) return;

    final comment = PostComment(author: 'Safeer Hussain', text: text.trim());

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      runInAction(() {
        _posts[index].comments.add(comment);
      });
    }

    await socialRepository.addComment(postId, comment);
  }

  Future<void> createPost({
    required String title,
    required String description,
    required String postType,
    required Map<String, dynamic> metrics,
  }) async {
    final newPost = SocialPost(
      id: const Uuid().v4(),
      userName: 'Safeer Hussain',
      userHandle: '@safeer_h',
      avatarInitials: 'SH',
      postType: postType,
      title: title,
      description: description,
      metrics: metrics,
      likesCount: 1,
      isLiked: true,
      comments: [],
      timestamp: DateTime.now(),
    );

    runInAction(() {
      _posts.insert(0, newPost);
    });

    await socialRepository.createPost(newPost);
  }

  Future<void> repostMilestone(SocialPost post) async {
    final repost = SocialPost(
      id: const Uuid().v4(),
      userName: 'Safeer Hussain',
      userHandle: '@safeer_h',
      avatarInitials: 'SH',
      postType: post.postType,
      title: 'Repost: ${post.title}',
      description: 'Shared from ${post.userName}: ${post.description}',
      metrics: Map<String, dynamic>.from(post.metrics),
      likesCount: 1,
      isLiked: true,
      comments: [],
      timestamp: DateTime.now(),
    );

    runInAction(() {
      _posts.insert(0, repost);
    });

    await socialRepository.createPost(repost);
  }
}
