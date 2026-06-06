import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../core/widgets/skeletons.dart';
import '../../core/utils/page_transitions.dart';
import '../project/create_project_screen.dart';
import '../post/create_post_screen.dart';
import '../post/post_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import 'widgets/post_card.dart';

/// Главная экран с лентой подписок — стиль Instagram 2025
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchUnreadNotifications();
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
      final response = await ApiService.instance.getNotifications();
      final unread = response.where((n) => n['is_read'] != true).length;
      if (mounted) setState(() => _unreadNotifications = unread);
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  Future<void> _onRefresh() async {
    final _ = ref.refresh(postsStreamProvider);
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(followingPostsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceDark,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.backgroundDark,
              scrolledUnderElevation: 0,
              title: Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_box_outlined),
                  iconSize: 26,
                  onPressed: () => _showCreateMenu(context),
                ),
                IconButton(
                  icon: Badge(
                    smallSize: 8,
                    isLabelVisible: _unreadNotifications > 0,
                    label: _unreadNotifications > 0
                        ? Text(
                            '$_unreadNotifications',
                            style: const TextStyle(fontSize: 9),
                          )
                        : null,
                    child: const Icon(Icons.favorite_border),
                  ),
                  iconSize: 24,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      slideTransition(const NotificationsScreen()),
                    );
                    _fetchUnreadNotifications();
                  },
                ),
              ],
            ),

            // Feed
            postsAsync.when(
              data: (posts) {
                debugPrint('HomeScreen: rendering ${posts.length} posts');
                for (var post in posts) {
                  debugPrint(
                      '  - Post by: ${post.author.name}, content: ${post.content?.substring(0, post.content!.length > 30 ? 30 : post.content!.length)}');
                }

                // Если Firestore пуст — используем локальные посты
                var allPosts = posts;
                if (allPosts.isEmpty) {
                  allPosts = ref.watch(postsProvider);
                }
                if (allPosts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 60),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= allPosts.length) {
                          return _buildLoadingIndicator();
                        }
                        return PostCard(
                          post: allPosts[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              slideTransition(PostDetailScreen(
                                post: allPosts[index],
                              )),
                            );
                          },
                        );
                      },
                      childCount: allPosts.length + 1,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.only(bottom: 60),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const PostCardSkeleton(),
                    childCount: 3,
                  ),
                ),
              ),
              error: (error, stack) {
                // Fallback на мок-данные
                final posts = ref.watch(postsProvider);
                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 60),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= posts.length)
                          return const SizedBox.shrink();
                        return PostCard(
                          post: posts[index],
                          onTap: () {},
                        );
                      },
                      childCount: posts.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textDarkSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Пока нет постов',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте первый проект или пост',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (!_isLoading) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.all(24),
      child: PostCardSkeleton(),
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.textDarkSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading:
                  const Icon(Icons.article_outlined, color: AppColors.primary),
              title: const Text('Создать пост',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: const Text('Текст, фото, теги',
                  style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context, bottomUpTransition(const CreatePostScreen()));
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.folder_outlined, color: AppColors.accent),
              title: const Text('Создать проект',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: const Text('Описание, навыки, ZIP',
                  style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context, bottomUpTransition(const CreateProjectScreen()));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
