import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/theme_store.dart';
import '../stores/social_store.dart';
import '../widgets/leaderboard_view.dart';
import '../widgets/social_post_card.dart';

class SocialFeedView extends StatefulWidget {
  const SocialFeedView({super.key});

  @override
  State<SocialFeedView> createState() => _SocialFeedViewState();
}

class _SocialFeedViewState extends State<SocialFeedView> {
  late final SocialStore _store;
  final ThemeStore _themeStore = sl<ThemeStore>();

  @override
  void initState() {
    super.initState();
    _store = sl<SocialStore>();
    _store.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final _ = _themeStore.themeMode;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Community & Leaderboards'),
              bottom: TabBar(
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(text: 'Athlete Feed'),
                  Tab(text: 'Weekly Rankings'),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => _store.loadFeed(),
                  icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
                ),
              ],
            ),
            body: TabBarView(
              children: [
                _buildFeedTab(colorScheme, isLandscape),
                const LeaderboardView(),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'fab_social_feed',
              onPressed: () => _showCreatePostDialog(context, colorScheme),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text(
                'Share Milestone',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedTab(ColorScheme colorScheme, bool isLandscape) {
    return Observer(
      builder: (_) {
        if (_store.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        final posts = _store.posts;
        if (posts.isEmpty) {
          return Center(
            child: Text(
              'No community posts found.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        if (isLandscape) {
          return RefreshIndicator(
            onRefresh: () => _store.loadFeed(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: SocialPostCard(post: posts[index], store: _store),
                );
              },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _store.loadFeed(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return SocialPostCard(post: posts[index], store: _store);
            },
          ),
        );
      },
    );
  }

  void _showCreatePostDialog(BuildContext context, ColorScheme colorScheme) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Share Fitness Milestone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Milestone Title (e.g. 10K Personal Record)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Context & ring biometric recovery details',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final t = titleCtrl.text.trim();
                          final d = descCtrl.text.trim();
                          if (t.isNotEmpty && d.isNotEmpty) {
                            _store.createPost(
                              title: t,
                              description: d,
                              postType: 'WORKOUT_MILESTONE',
                              metrics: {
                                'status': 'Completed',
                                'volumeKg': 3400,
                              },
                            );
                            Navigator.of(ctx).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Publish Post',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
