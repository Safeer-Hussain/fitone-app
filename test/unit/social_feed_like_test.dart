import 'package:fitone/domain/entities/social_post.dart';
import 'package:fitone/domain/repositories/social_repository.dart';
import 'package:fitone/presentation/social_feed/stores/social_store.dart';
import 'package:fitone/presentation/social_feed/widgets/social_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSocialRepo implements SocialRepository {
  final List<SocialPost> feed = [];

  @override
  Future<List<SocialPost>> getCommunityFeed() async => feed;

  @override
  Future<void> toggleLike(String postId, bool isLiked) async {
    final idx = feed.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = feed[idx];
      feed[idx] = p.copyWith(
        isLiked: isLiked,
        likesCount: isLiked
            ? p.likesCount + 1
            : (p.likesCount > 0 ? p.likesCount - 1 : 0),
      );
    }
  }

  @override
  Future<void> addComment(String postId, PostComment comment) async {}

  @override
  Future<void> createPost(SocialPost post) async {
    feed.insert(0, post);
  }
}

void main() {
  group('SocialFeedStore Like Reactivity Tests', () {
    late _FakeSocialRepo fakeRepo;
    late SocialStore socialStore;
    late SocialPost samplePost;

    setUp(() {
      samplePost = SocialPost(
        id: 'post_01',
        userName: 'Alex Honnold',
        userHandle: '@alex_climbs',
        avatarInitials: 'AH',
        postType: 'MILESTONE',
        title: 'Dawn Wall Free Solo Prep',
        description: 'Zone 2 cardio and ring grip strength intervals complete.',
        metrics: {'Volume': '12,500kg', 'HRV': '78ms'},
        likesCount: 14,
        isLiked: false,
        comments: [],
        timestamp: DateTime.now(),
      );

      fakeRepo = _FakeSocialRepo();
      fakeRepo.feed.add(samplePost);
      socialStore = SocialStore(socialRepository: fakeRepo);
    });

    test('toggleLike mutates state and updates like count instantly in SocialFeedStore', () async {
      await socialStore.loadFeed();
      expect(socialStore.posts.length, equals(1));
      expect(socialStore.posts.first.isLiked, isFalse);
      expect(socialStore.posts.first.likesCount, equals(14));

      // Like the post
      await socialStore.toggleLike('post_01');
      expect(socialStore.posts.first.isLiked, isTrue);
      expect(socialStore.posts.first.likesCount, equals(15));

      // Unlike the post
      await socialStore.toggleLike('post_01');
      expect(socialStore.posts.first.isLiked, isFalse);
      expect(socialStore.posts.first.likesCount, equals(14));
    });

    testWidgets(
      'SocialPostCard re-renders heart icon and like count reactively on tap',
      (tester) async {
        await socialStore.loadFeed();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialPostCard(
                post: socialStore.posts.first,
                store: socialStore,
              ),
            ),
          ),
        );

        // Verify initial unliked state
        expect(find.text('14'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.favorite_rounded), findsNothing);

        // Tap like button
        final likeButton = find.byType(IconButton).first;
        await tester.tap(likeButton);
        await tester.pump();

        // Assert instant UI update without full reload
        expect(find.text('15'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);

        // Tap again to unlike
        await tester.tap(likeButton);
        await tester.pump();

        expect(find.text('14'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      },
    );
  });
}
