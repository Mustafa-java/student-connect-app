import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../core/widgets/smart_image.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';
import '../../core/utils/page_transitions.dart';
import '../../services/api_service.dart';
import '../project/create_project_screen.dart';
import '../post/create_post_screen.dart';
import '../project/project_detail_screen.dart';
import '../post/post_detail_screen.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';
import 'followers_screen.dart';
import 'my_projects_screen.dart';
import 'skills_screen.dart';
import 'achievements_screen.dart';
import '../teams/my_teams_screen.dart';

/// Экран профиля — стиль Instagram 2025
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  List<Post> _savedPosts = [];
  List<Project> _savedProjects = [];
  bool _savedLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedItems() async {
    if (_savedLoading) return;
    setState(() => _savedLoading = true);
    final results = await Future.wait([
      ApiService.instance.getSavedPosts(),
      ApiService.instance.getSavedProjects(),
    ]);
    if (mounted) {
      setState(() {
        _savedPosts = results[0] as List<Post>;
        _savedProjects = results[1] as List<Project>;
        _savedLoading = false;
      });
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      if (_tabController.index == 2) {
        _loadSavedItems();
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      final _ = ref.refresh(currentUserProvider);
    }
  }

  void _handleLogout() async {
    Navigator.pop(context);
    await ref.read(authStatusProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Проекты и посты пользователя из реального API (stream)
    final projectsAsync = ref.watch(projectsStreamProvider);
    final postsAsync = ref.watch(postsStreamProvider);

    return projectsAsync.when(
      data: (allProjects) {
        final userProjects =
            allProjects.where((p) => p.author.id == user.id).toList();
        return postsAsync.when(
          data: (allPosts) {
            final userPosts =
                allPosts.where((p) => p.author.id == user.id).toList();
            return _buildProfileContent(context, user, userPosts, userProjects);
          },
          loading: () => _buildProfileContent(context, user, [], userProjects),
          error: (_, __) =>
              _buildProfileContent(context, user, [], userProjects),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildProfileContent(context, user, [], []),
    );
  }

  Widget _buildProfileContent(BuildContext context, User user,
      List<Post> userPosts, List<Project> userProjects) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceDark,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.backgroundDark,
              title: Row(
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.textDarkSecondary,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_box_outlined, size: 26),
                  onPressed: () => _showCreateMenu(context),
                ),
                IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 26),
                  onPressed: _showMenuBottomSheet,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CustomAvatar(
                          radius: 40,
                          imageUrl: user.avatarUrl,
                          hasStoryGradient: true,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('${user.projectsCount}', 'Проекты',
                                  onTap: null),
                              _buildStatItem('${user.followersCount}', 'Подп.',
                                  onTap: () => _openFollowersScreen(user,
                                      showFollowers: true)),
                              _buildStatItem(
                                  '${user.followingCount}', 'Подписки',
                                  onTap: () => _openFollowersScreen(user,
                                      showFollowers: false)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.bio!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                    if (user.university != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.school_rounded,
                              size: 14, color: AppColors.textDarkSecondary),
                          const SizedBox(width: 4),
                          Text(
                            user.university!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textDarkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                slideTransition(const EditProfileScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceDark,
                              foregroundColor: AppColors.textDark,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Редактировать',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceDark,
                              foregroundColor: AppColors.textDark,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Поделиться',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (user.skills.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: user.skills
                            .map((skill) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
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
            SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildHighlight(
                      'Мои проекты',
                      Icons.folder_outlined,
                      () => Navigator.push(
                          context, slideTransition(const MyProjectsScreen())),
                    ),
                    _buildHighlight(
                      'Навыки',
                      Icons.workspace_premium_outlined,
                      () => Navigator.push(
                          context, slideTransition(const SkillsScreen())),
                    ),
                    _buildHighlight(
                      'Команды',
                      Icons.groups_outlined,
                      () => Navigator.push(
                          context, slideTransition(const MyTeamsScreen())),
                    ),
                    _buildHighlight(
                      'Достижения',
                      Icons.emoji_events_outlined,
                      () => Navigator.push(
                          context, slideTransition(const AchievementsScreen())),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(height: 1, thickness: 0.5),
            ),
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
                    Tab(text: 'Посты'),
                    Tab(text: 'Проекты'),
                    Tab(icon: Icon(Icons.bookmark_border_rounded, size: 22)),
                    Tab(icon: Icon(Icons.person_pin_outlined, size: 22)),
                  ],
                  dividerColor: Colors.transparent,
                ),
              ),
            ),
            // Таб 0: Посты
            if (_selectedTabIndex == 0)
              userPosts.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(
                        Icons.post_add_outlined,
                        'Нет постов',
                        'Создайте первый пост',
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
            // Таб 1: Проекты
            if (_selectedTabIndex == 1)
              userProjects.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(
                        Icons.folder_open,
                        'Нет проектов',
                        'Создайте свой первый проект',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(2),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
            // Таб 2: Сохранённые
            if (_selectedTabIndex == 2)
              _savedPosts.isEmpty && _savedProjects.isEmpty && !_savedLoading
                  ? SliverToBoxAdapter(
                      child: SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_border,
                                  size: 60, color: AppColors.textDarkSecondary),
                              const SizedBox(height: 16),
                              Text(
                                'Нет сохраненных',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textDarkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index < _savedPosts.length) {
                              return _buildPostListItem(_savedPosts[index]);
                            }
                            return const SizedBox.shrink();
                          },
                          childCount: _savedPosts.length,
                        ),
                      ),
                    ),
            // Таб 3: О себе
            if (_selectedTabIndex == 3)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'О себе',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.person_outline, 'Имя', user.name),
                      if (user.email.isNotEmpty)
                        _buildInfoRow(
                            Icons.email_outlined, 'Email', user.email),
                      if (user.bio != null && user.bio!.isNotEmpty)
                        _buildInfoRow(Icons.edit_outlined, 'Био', user.bio!),
                      if (user.university != null)
                        _buildInfoRow(Icons.school_outlined, 'Университет',
                            user.university!),
                      if (user.faculty != null)
                        _buildInfoRow(Icons.menu_book_outlined, 'Факультет',
                            user.faculty!),
                      if (user.course != null)
                        _buildInfoRow(Icons.calendar_today_outlined, 'Курс',
                            user.course!),
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
                        children: user.skills
                            .map((skill) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
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
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildPostListItem(Post post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          slideTransition(PostDetailScreen(post: post)),
        );
      },
      onLongPress: () => _confirmDeletePost(post),
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
                      Text('${post.likesCount}',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDarkSecondary)),
                      const SizedBox(width: 8),
                      Icon(Icons.chat_bubble_outline,
                          size: 14, color: AppColors.textDarkSecondary),
                      const SizedBox(width: 4),
                      Text('${post.commentsCount}',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDarkSecondary)),
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

  Widget _buildStatItem(String value, String label, {VoidCallback? onTap}) {
    final widget = Column(
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

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }
    return widget;
  }

  void _openFollowersScreen(User user, {required bool showFollowers}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersScreen(
          userId: user.id,
          userName: user.name,
          showFollowers: showFollowers,
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
      onLongPress: () => _confirmDeleteProject(project),
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
                  const Icon(Icons.chat_bubble, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${project.commentsCount}',
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

  Widget _buildHighlight(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: AppColors.textDarkSecondary,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(
            icon,
            size: 60,
            color: AppColors.textDarkSecondary,
          ),
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

  Future<void> _confirmDeletePost(Post post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить пост',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: const Text(
            'Вы уверены, что хотите удалить этот пост? Это действие нельзя отменить.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена',
                  style: TextStyle(color: AppColors.textDarkSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ApiService.instance.deletePost(post.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Пост удалён'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Обновляем список постов
          ref.invalidate(postsStreamProvider);
          ref.invalidate(currentUserProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось удалить пост'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить проект',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: const Text(
            'Вы уверены, что хотите удалить этот проект? Все файлы будут удалены. Это действие нельзя отменить.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена',
                  style: TextStyle(color: AppColors.textDarkSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ApiService.instance.deleteProject(project.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Проект удалён'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Обновляем список проектов
          ref.invalidate(projectsStreamProvider);
          ref.invalidate(currentUserProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось удалить проект'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showMenuBottomSheet() {
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textDarkSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildMenuItem(Icons.settings_outlined, 'Настройки'),
            _buildMenuItem(Icons.history, 'Архив'),
            _buildMenuItem(Icons.qr_code, 'QR-код профиля'),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                'Выйти',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          slideTransition(const SettingsScreen()),
        );
      },
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
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
