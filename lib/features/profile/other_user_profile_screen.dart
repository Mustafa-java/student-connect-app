import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../core/widgets/smart_image.dart';
import '../../core/utils/page_transitions.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../project/project_detail_screen.dart';
import '../post/post_detail_screen.dart';
import '../messages/chat_screen.dart';

/// Экран просмотра чужого профиля
class OtherUserProfileScreen extends ConsumerStatefulWidget {
  final User user;

  const OtherUserProfileScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends ConsumerState<OtherUserProfileScreen> {
  bool _isFollowing = false;
  bool _isLoadingFollowStatus = true;
  String? _chatId;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
    _findExistingChat();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFollowStatus() async {
    try {
      final status = await ApiService.instance.getFollowStatus(widget.user.id);
      if (mounted) {
        setState(() {
          _isFollowing = status;
          _isLoadingFollowStatus = false;
        });
      }
    } catch (e) {
      debugPrint('loadFollowStatus error: $e');
      if (mounted) {
        setState(() {
          _isLoadingFollowStatus = false;
        });
      }
    }
  }

  Future<void> _findExistingChat() async {
    try {
      final chats = await ApiService.instance.getChats();
      for (final chatData in chats) {
        final otherUser = chatData['other_user'] as Map<String, dynamic>?;
        if (otherUser?['id'] == widget.user.id) {
          if (mounted) {
            setState(() {
              _chatId = chatData['id'] as String?;
            });
          }
          break;
        }
      }
    } catch (e) {
      debugPrint('findExistingChat error: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isFollowing = !_isFollowing;
    });

    try {
      final isFollowing = await ApiService.instance.toggleFollow(widget.user.id);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });

        // Обновляем счётчики
        ref.invalidate(currentUserProvider);
      }
    } catch (e) {
      debugPrint('toggleFollow error: $e');
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing; // Откат
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при изменении подписки'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openChat() async {
    try {
      // Если чат уже существует, открываем его
      if (_chatId != null) {
        final chats = await ApiService.instance.getChats();
        final chatData = chats.firstWhere(
          (c) => c['id'] == _chatId,
          orElse: () => <String, dynamic>{},
        );

        if (chatData.isNotEmpty) {
          final chat = _parseChat(chatData);
          if (mounted) {
            Navigator.push(
              context,
              slideTransition(ChatScreen(chat: chat)),
            );
          }
          return;
        }
      }

      // Создаём новый чат
      final newChatId = await ApiService.instance.createChat(widget.user.id);
      final chats = await ApiService.instance.getChats();
      final chatData = chats.firstWhere(
        (c) => c['id'] == newChatId,
        orElse: () => <String, dynamic>{},
      );

      if (chatData.isNotEmpty && mounted) {
        final chat = _parseChat(chatData);
        setState(() {
          _chatId = newChatId;
        });
        Navigator.push(
          context,
          slideTransition(ChatScreen(chat: chat)),
        );
      }
    } catch (e) {
      debugPrint('openChat error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при открытии чата: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Chat _parseChat(Map<String, dynamic> data) {
    final otherUser = data['other_user'] as Map<String, dynamic>?;
    final user = otherUser != null
        ? User(
            id: otherUser['id'] ?? '',
            name: otherUser['name'] ?? 'Пользователь',
            email: otherUser['email'] ?? '',
            avatarUrl: otherUser['avatar_url'],
            isOnline: _toBool(otherUser['is_online']),
            createdAt: DateTime.now(),
            skills: [],
            projectsCount: 0,
            followersCount: 0,
            followingCount: 0,
          )
        : widget.user;

    return Chat(
      id: data['id'] ?? '',
      currentUser: user,
      unreadCount: data['unread_count'] ?? 0,
      isOnline: _toBool(data['is_online']),
      lastMessageAt: data['last_message_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['last_message_at'])
          : null,
      createdAt: data['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
          : DateTime.now(),
    );
  }

  /// Преобразуем int или bool в bool
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);
    final postsAsync = ref.watch(postsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: DefaultTabController(
        length: 3,
        initialIndex: 0,
        child: projectsAsync.when(
          data: (allProjects) {
            final userProjects = allProjects.where((p) => p.author.id == widget.user.id).toList();
            return postsAsync.when(
              data: (allPosts) {
                final userPosts = allPosts.where((p) => p.author.id == widget.user.id).toList();
                return _buildProfileContent(currentUser, userPosts, userProjects);
              },
              loading: () => _buildProfileContent(currentUser, [], userProjects),
              error: (_, __) => _buildProfileContent(currentUser, [], userProjects),
            );
          },
          loading: () => const Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки данных',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    User? currentUser,
    List<Post> userPosts,
    List<Project> userProjects,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          backgroundColor: AppColors.backgroundDark,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.backgroundDark,
                  ],
                ),
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () => _showOptionsBottomSheet(),
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
                      imageUrl: widget.user.avatarUrl,
                      hasStoryGradient: false,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('${widget.user.projectsCount}', 'Проекты'),
                          _buildStatItem('${widget.user.followersCount}', 'Подп.'),
                          _buildStatItem('${widget.user.followingCount}', 'Подписки'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Имя и био
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.user.bio!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDarkSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (widget.user.university != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_rounded,
                          size: 14, color: AppColors.textDarkSecondary),
                      const SizedBox(width: 4),
                      Text(
                        widget.user.university!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Кнопки действий
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        text: _isFollowing ? 'Отписаться' : 'Подписаться',
                        icon: _isFollowing ? Icons.person_remove : Icons.person_add,
                        onPressed: _toggleFollow,
                        isPrimary: _isFollowing,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        text: 'Сообщение',
                        icon: Icons.send_rounded,
                        onPressed: _openChat,
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
                // Навыки
                if (widget.user.skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: widget.user.skills
                        .map((skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
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
              ],
            ),
          ),
        ),
        // Табы
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverTabBarDelegate(
            TabBar(
              indicatorColor: AppColors.textDark,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.textDark,
              unselectedLabelColor: AppColors.textDarkSecondary,
              tabs: const [
                Tab(text: 'Посты'),
                Tab(text: 'Проекты'),
                Tab(text: 'О себе'),
              ],
              dividerColor: Colors.transparent,
              onTap: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
          ),
        ),
        // Контент табов
        if (_selectedTabIndex == 0)
          userPosts.isEmpty
              ? SliverToBoxAdapter(
                  child: _buildEmptyState(
                    Icons.post_add_outlined,
                    'Нет постов',
                    'Пользователь ещё не создал посты',
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = userPosts[index];
                        return _buildPostListItem(post);
                      },
                      childCount: userPosts.length,
                    ),
                  ),
                ),
        if (_selectedTabIndex == 1)
          userProjects.isEmpty
              ? SliverToBoxAdapter(
                  child: _buildEmptyState(
                    Icons.folder_open,
                    'Нет проектов',
                    'Пользователь ещё не создал проекты',
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(2),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final project = userProjects[index];
                        return _buildProjectGridItem(project);
                      },
                      childCount: userProjects.length,
                    ),
                  ),
                ),
        if (_selectedTabIndex == 2)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'О пользователе',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.person_outline, 'Имя', widget.user.name),
                  if (widget.user.email.isNotEmpty)
                    _buildInfoRow(Icons.email_outlined, 'Email', widget.user.email),
                  if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
                    _buildInfoRow(Icons.edit_outlined, 'Био', widget.user.bio!),
                  if (widget.user.university != null)
                    _buildInfoRow(Icons.school_outlined, 'Университет', widget.user.university!),
                  if (widget.user.faculty != null)
                    _buildInfoRow(Icons.menu_book_outlined, 'Факультет', widget.user.faculty!),
                  if (widget.user.course != null)
                    _buildInfoRow(Icons.calendar_today_outlined, 'Курс', widget.user.course!),
                  const SizedBox(height: 16),
                  const Text(
                    'Навыки',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.user.skills
                        .map((skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
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
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoadingFollowStatus && text.contains('Подпис') ? null : onPressed,
      icon: _isLoadingFollowStatus && text.contains('Подпис')
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.primary : AppColors.surfaceDark,
        foregroundColor: isPrimary ? Colors.white : AppColors.textDark,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textDarkSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textDarkSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostListItem(Post post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          slideTransition(PostDetailScreen(post: post)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            if (post.images.isNotEmpty)
              SmartImage(
                imageUrl: post.images.first,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article_outlined,
                    size: 20, color: AppColors.textDarkSecondary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.favorite_border,
                          size: 14, color: AppColors.textDarkSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDarkSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chat_bubble_outline,
                          size: 14, color: AppColors.textDarkSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentsCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textDarkSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectGridItem(Project project) {
    final imageUrl = project.images.isNotEmpty
        ? project.images.first
        : 'https://picsum.photos/seed/${project.id}/300/300';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          scaleTransition(ProjectDetailScreen(project: project)),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          SmartImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
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
                    '${project.likesCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.visibility, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${project.viewsCount}',
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

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: AppColors.textDarkSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Поделиться профилем'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Пожаловаться'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Report functionality
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.backgroundDark,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
