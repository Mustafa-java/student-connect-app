import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../core/utils/page_transitions.dart';
import '../../providers/app_providers.dart';
import '../messages/chat_screen.dart';
import '../project/project_detail_screen.dart';
import '../../models/models.dart';

/// Экран просмотра профиля другого пользователя
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatarUrl;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.backgroundDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Аватар + статистика
                  Row(
                    children: [
                      CustomAvatar(
                        radius: 40,
                        imageUrl: widget.userAvatarUrl,
                        hasStoryGradient: true,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem('5', 'Проекты'),
                            _buildStatItem('128', 'Подп.'),
                            _buildStatItem('89', 'Подписки'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Имя + био
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Разработчик | Студент',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textDarkSecondary,
                    ),
                    textAlign: TextAlign.left,
                  ),

                  const SizedBox(height: 14),

                  // Кнопки
                  Consumer(
                    builder: (context, ref, _) {
                      final currentUser = ref.watch(currentUserProvider);
                      final isFollowing = ref.watch(followStatusProvider(widget.userId));

                      return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: currentUser != null ? () {
                            ref.read(followStatusProvider(widget.userId).notifier)
                                .toggleFollow(currentUser.id);
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? AppColors.surfaceDark
                                : AppColors.primary,
                            foregroundColor: isFollowing
                                ? AppColors.textDark
                                : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isFollowing ? 'Подписка' : 'Подписаться',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              slideTransition(ChatScreen(
                                chat: Chat(
                                  id: 'chat_${widget.userId}',
                                  currentUser: User(
                                    id: widget.userId,
                                    name: widget.userName,
                                    email: '',
                                    avatarUrl: widget.userAvatarUrl,
                                    createdAt: DateTime.now(),
                                  ),
                                  unreadCount: 0,
                                  isOnline: false,
                                  lastMessageAt: DateTime.now(),
                                  createdAt: DateTime.now(),
                                ),
                              )),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textDark,
                            side: const BorderSide(color: AppColors.divider),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Написать',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                    },
                  ),

                  // Навыки
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['Flutter', 'Dart', 'Firebase']
                        .map((skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          // Табы
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.textDark,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.textDark,
                unselectedLabelColor: AppColors.textDarkSecondary,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
                  Tab(icon: Icon(Icons.bookmark_border_rounded, size: 22)),
                ],
                dividerColor: Colors.transparent,
              ),
            ),
          ),

          // Контент
          SliverPadding(
            padding: const EdgeInsets.all(2),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildProjectGridItem(index);
                },
                childCount: 6,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textDarkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectGridItem(int index) {
    final projects = [
      Project(
        id: 'proj_${widget.userId}_$index',
        title: 'Проект $index',
        description: 'Описание проекта',
        author: User(
            id: widget.userId,
            name: widget.userName,
            email: '',
            createdAt: DateTime.now()),
        images: [
          'https://picsum.photos/seed/user${widget.userId}$index/300/300'
        ],
        skills: ['Flutter', 'Dart'],
        status: 'in_progress',
        likesCount: index * 10,
        commentsCount: index * 3,
        viewsCount: index * 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    final project = projects.first;
    final imageUrl = project.images.first;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          slideTransition(ProjectDetailScreen(project: project)),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.skeleton,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surfaceDark,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textDarkSecondary,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${index * 10}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.backgroundDark,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) => false;
}
