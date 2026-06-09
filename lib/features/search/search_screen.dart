import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../core/widgets/smart_image.dart';
import '../../core/widgets/post_video_player.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../data/mock/mock_projects.dart';
import '../profile/other_user_profile_screen.dart';
import '../profile/profile_screen.dart';
import '../project/project_detail_screen.dart';
import '../post/post_detail_screen.dart';

/// Экран поиска — 4 подраздела: Проекты, Студенты, Навыки, Университеты
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0;
  String _query = '';
  String? _selectedSkill;
  String? _selectedUniversity;

  int get _currentTabCount => _selectedUniversity != null ? 4 : 5;

  TabController get tabController {
    if (_tabController == null || _tabController!.length != _currentTabCount) {
      _tabController?.dispose();
      _tabController = TabController(length: _currentTabCount, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }
    return _tabController!;
  }

  @override
  void initState() {
    super.initState();
    // Инициализация при первом обращении через getter
  }

  @override
  void dispose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = tabController.index;
        // Не сбрасываем университет при переключении табов!
        // _selectedSkill и _selectedUniversity остаются
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value.toLowerCase().trim();
      if (_query.isEmpty && _selectedUniversity != null) {
        _selectedUniversity = null;
      }
    });
  }

  void _filterBySkill(String skill) {
    setState(() {
      _selectedSkill = skill;
      _searchController.text = skill;
      _query = skill.toLowerCase();
      _selectedTabIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        tabController.animateTo(0);
      }
    });
  }

  void _filterByUniversity(String university) {
    setState(() {
      _selectedUniversity = university;
      _searchController.text = university;
      _query = university.toLowerCase();
      _selectedTabIndex = 0;
    });
    // TabController будет пересоздан при следующем обращении через getter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        tabController.animateTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.backgroundDark,
            title: const Text(
              'Поиск',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            actions: [
              if (_selectedSkill != null || _selectedUniversity != null)
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  tooltip: _selectedUniversity != null
                      ? 'Сбросить фильтр: $_selectedUniversity'
                      : 'Сбросить все фильтры',
                  onPressed: () {
                    setState(() {
                      _selectedSkill = null;
                      _selectedUniversity = null;
                      _searchController.clear();
                      _query = '';
                    });
                  },
                ),
            ],
          ),

          // Поисковая строка
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Поиск проектов, студентов, навыков...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {
                              _selectedSkill = null;
                              _selectedUniversity = null;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),

          // Активный фильтр (только для навыков, университет скрыт)
          if (_selectedSkill != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Навык: $_selectedSkill',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedSkill = null);
                        },
                        child: Icon(Icons.close,
                            size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Табы
          SliverToBoxAdapter(
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textDarkSecondary,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: _selectedUniversity != null
                  ? const [
                      Tab(text: 'Студенты'),
                      Tab(text: 'Посты'),
                      Tab(text: 'Проекты'),
                      Tab(text: 'Навыки'),
                    ]
                  : const [
                      Tab(text: 'Посты'),
                      Tab(text: 'Проекты'),
                      Tab(text: 'Студенты'),
                      Tab(text: 'Навыки'),
                      Tab(text: 'Вузы'),
                    ],
              dividerColor: Colors.transparent,
            ),
          ),

          // Контент таба
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: _buildTabContent(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildTabContent() {
    // Если выбран университет - показываем специальные вкладки
    if (_selectedUniversity != null) {
      switch (_selectedTabIndex) {
        case 0:
          return _buildUniversityStudentsTab();
        case 1:
          return _buildUniversityPostsTab();
        case 2:
          return _buildUniversityProjectsTab();
        case 3:
          return _buildUniversitySkillsTab();
        default:
          return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
    }

    // Обычные вкладки
    switch (_selectedTabIndex) {
      case 0:
        return _buildPostsTab();
      case 1:
        return _buildProjectsTab();
      case 2:
        return _buildStudentsTab();
      case 3:
        return _buildSkillsTab();
      case 4:
        return _buildUniversitiesTab();
      default:
        return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }

  // ==================== ПОСТЫ ====================
  Widget _buildPostsTab() {
    final postsAsync = ref.watch(postsStreamProvider);

    return postsAsync.when(
      data: (posts) {
        var filtered = posts;
        if (_query.isNotEmpty) {
          filtered = posts.where((p) {
            final content = (p.content ?? '').toLowerCase();
            final title = p.title.toLowerCase();
            final tags = p.tags.map((t) => t.toLowerCase());
            return content.contains(_query) ||
                title.contains(_query) ||
                tags.any((t) => t.contains(_query));
          }).toList();
        }

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
                'Посты не найдены', 'Попробуйте изменить запрос'),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildPostCard(filtered[index]),
            childCount: filtered.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) {
        final posts = ref.watch(postsProvider);
        var filtered = posts;
        if (_query.isNotEmpty) {
          filtered = posts.where((p) {
            final content = (p.content ?? '').toLowerCase();
            final title = p.title.toLowerCase();
            final tags = p.tags.map((t) => t.toLowerCase());
            return content.contains(_query) ||
                title.contains(_query) ||
                tags.any((t) => t.contains(_query));
          }).toList();
        }

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
                'Посты не найдены', 'Попробуйте изменить запрос'),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildPostCard(filtered[index]),
            childCount: filtered.length,
          ),
        );
      },
    );
  }

  Widget _buildPostCard(Post post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Автор
            Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(post.author),
                  child: CustomAvatar(
                    radius: 16,
                    imageUrl: post.author.avatarUrl,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToProfile(post.author),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (post.author.university != null)
                          Text(
                            post.author.university!,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textDarkSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Text(
                  _getTimeAgo(post.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textDarkSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Контент
            Text(
              post.content ?? post.title,
              style: const TextStyle(fontSize: 14, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Медиа (видео или изображение)
            if ((post.videoUrl != null && post.videoUrl!.isNotEmpty) || post.images.isNotEmpty) ...[
              const SizedBox(height: 10),
              if (post.videoUrl != null && post.videoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: PostVideoPlayer(
                    videoUrl: post.videoUrl!,
                    thumbnailUrl: post.videoThumbnailUrl,
                    height: 180,
                  ),
                )
              else if (post.images.isNotEmpty)
                SmartImage(
                  imageUrl: post.images.first,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                ),
            ],
            // Теги
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: post.tags.take(3).map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            // Статистика
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.favorite_border,
                    size: 16, color: AppColors.textDarkSecondary),
                const SizedBox(width: 4),
                Text('${post.likesCount}',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textDarkSecondary)),
                const SizedBox(width: 12),
                Icon(Icons.chat_bubble_outline,
                    size: 16, color: AppColors.textDarkSecondary),
                const SizedBox(width: 4),
                Text('${post.commentsCount}',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textDarkSecondary)),
                const SizedBox(width: 12),
                Icon(Icons.visibility_outlined,
                    size: 16, color: AppColors.textDarkSecondary),
                const SizedBox(width: 4),
                Text('${post.sharesCount}',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textDarkSecondary)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 250),
          delay: Duration(milliseconds: 50),
        );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'сейчас';
    if (diff.inHours < 1) return '${diff.inMinutes} мин.';
    if (diff.inDays < 1) return '${diff.inHours} ч.';
    if (diff.inDays < 7) return '${diff.inDays} дн.';
    return '${dateTime.day}.${dateTime.month}';
  }

  void _navigateToProfile(User user) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && user.id == currentUser.id) {
      // Переход к своему профилю
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      // Переход к чужому профилю
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OtherUserProfileScreen(user: user)),
      );
    }
  }

  // ==================== ПРОЕКТЫ ====================
  Widget _buildProjectsTab() {
    final projectsAsync = ref.watch(projectsStreamProvider);

    return projectsAsync.when(
      data: (projects) {
        var allProjects = projects;
        if (allProjects.isEmpty) {
          allProjects = MockProjects.projects;
        }

        var filtered = allProjects;
        if (_query.isNotEmpty) {
          filtered = allProjects.where((p) {
            final title = p.title.toLowerCase();
            final desc = p.description.toLowerCase();
            final skills = p.skills.map((s) => s.toLowerCase());
            return title.contains(_query) ||
                desc.contains(_query) ||
                skills.any((s) => s.contains(_query));
          }).toList();
        }

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child:
                _buildEmptyState('Проекты не найдены', 'Создайте первый проект!'),
          );
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildProjectCard(filtered[index]),
            childCount: filtered.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) {
        var allProjects = MockProjects.projects;
        var filtered = allProjects;
        if (_query.isNotEmpty) {
          filtered = allProjects.where((p) {
            final title = p.title.toLowerCase();
            final desc = p.description.toLowerCase();
            final skills = p.skills.map((s) => s.toLowerCase());
            return title.contains(_query) ||
                desc.contains(_query) ||
                skills.any((s) => s.contains(_query));
          }).toList();
        }

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child:
                _buildEmptyState('Проекты не найдены', 'Создайте первый проект!'),
          );
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildProjectCard(filtered[index]),
            childCount: filtered.length,
          ),
        );
      },
    );
  }

  Widget _buildProjectCard(Project project) {
    final imageUrl = project.images.isNotEmpty
        ? project.images.first
        : 'https://picsum.photos/seed/${project.id}/300/400';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(project: project),
          ),
        );
      },
      child: Container(
        height: 250,
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
            SmartImage(imageUrl: imageUrl, fit: BoxFit.cover),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  project.statusRu,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.favorite,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('${project.likesCount}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white)),
                        const SizedBox(width: 6),
                        const Icon(Icons.chat_bubble,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('${project.commentsCount}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 250),
          delay: Duration(milliseconds: 50),
        );
  }

  // ==================== СТУДЕНТЫ ====================
  Widget _buildStudentsTab() {
    return FutureBuilder<List<User>>(
      future: ApiService.instance.getAllUsers(),
      builder: (context, snapshot) {
        List<User> allUsers = [];
        if (snapshot.hasData) {
          allUsers = snapshot.data ?? [];
        }

        // Добавляем мок-студентов если Firestore пуст
        if (allUsers.isEmpty) {
          allUsers = AppConstants.defaultUniversities
              .map((uni) => _generateMockStudent(uni))
              .toList();
        }

        // Фильтрация
        var filtered = allUsers;
        if (_query.isNotEmpty) {
          filtered = allUsers.where((u) {
            return u.name.toLowerCase().contains(_query) ||
                (u.university?.toLowerCase().contains(_query) ?? false) ||
                (u.faculty?.toLowerCase().contains(_query) ?? false) ||
                u.skills.any((s) => s.toLowerCase().contains(_query));
          }).toList();
        }

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
              'Студенты не найдены',
              'Попробуйте изменить запрос',
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildStudentTile(filtered[index]),
            childCount: filtered.length,
          ),
        );
      },
    );
  }

  User _generateMockStudent(String university) {
    final names = [
      'Айбек Токтоналиев',
      'Айгуль Муратова',
      'Нурлан Калыбеков',
      'Бакыт Султанов',
      'Жибек Абдыкалыкова',
      'Эрлан Данияров',
      'Айпери Бекмуратова',
      'Тимур Жумабеков',
      'Арууке Нурланова',
      'Дастан Рысбеков',
      'Мээрим Кубатова',
      'Канат Абдиев',
      'Гульнара Садыкова',
      'Болот Мамытов',
      'Айжан Тилекова',
      'Нурзат Бакытова',
      'Эльдияр Касымов',
      'Жыргал Сагынбаева',
    ];
    final skills = [
      'Flutter',
      'Python',
      'UI/UX',
      'JavaScript',
      'Java',
      'Figma',
      'React',
      'Dart'
    ];
    final idx = university.hashCode % names.length;
    return User(
      id: 'user_${university.hashCode}',
      name: names[idx],
      email: '',
      avatarUrl: 'https://i.pravatar.cc/300?img=${(idx + 1) * 3}',
      university: university,
      faculty: 'Факультет ИТ',
      skills: skills.sublist(0, 2 + (idx % 3)),
      createdAt: DateTime.now(),
    );
  }

  Widget _buildStudentTile(User user) {
    return ListTile(
      leading: CustomAvatar(
        radius: 24,
        imageUrl: user.avatarUrl,
        hasStoryGradient: true,
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.university != null)
            Text(
              user.university!,
              style:
                  TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
            ),
          if (user.faculty != null)
            Text(
              user.faculty!,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textDarkSecondary.withValues(alpha: 0.7)),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: user.skills.take(3).map((skill) {
              return GestureDetector(
                onTap: () => _filterBySkill(skill),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      trailing: OutlinedButton(
        onPressed: () {
          final currentUser = ref.read(currentUserProvider);
          final isMyProfile = currentUser != null && user.id == currentUser.id;
          
          if (isMyProfile) {
            // Переходим на свой профиль
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          } else {
            // Переходим к чужому профилю
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    OtherUserProfileScreen(user: user),
                transitionsBuilder:
                    (context, value, secondaryAnimation, child) {
                  return FadeTransition(opacity: value, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: const Text('Профиль', style: TextStyle(fontSize: 12)),
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 250),
          delay: Duration(milliseconds: 50),
        );
  }

  // ==================== НАВЫКИ ====================
  Widget _buildSkillsTab() {
    final skills = AppConstants.defaultSkills;
    var filtered = skills;
    if (_query.isNotEmpty) {
      filtered = skills.where((s) => s.toLowerCase().contains(_query)).toList();
    }

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child:
            _buildEmptyState('Навыки не найдены', 'Попробуйте другой запрос'),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildSkillCard(filtered[index]),
        childCount: filtered.length,
      ),
    );
  }

  Widget _buildSkillCard(String skill) {
    final colors = [
      [AppColors.primary, AppColors.accent],
      [const Color(0xFF22C55E), const Color(0xFF10B981)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
    ];
    final gradient = colors[skill.hashCode % colors.length];

    return GestureDetector(
      onTap: () => _filterBySkill(skill),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 32,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 8),
            Text(
              skill,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Найти проекты →',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 250),
          delay: Duration(milliseconds: 50),
        );
  }

  // ==================== УНИВЕРСИТЕТЫ ====================
  Widget _buildUniversitiesTab() {
    final universities = AppConstants.defaultUniversities;
    var filtered = universities;
    if (_query.isNotEmpty) {
      filtered =
          universities.where((u) => u.toLowerCase().contains(_query)).toList();
    }

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState('Вузы не найдены', 'Попробуйте другой запрос'),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildUniversityTile(filtered[index]),
        childCount: filtered.length,
      ),
    );
  }

  Widget _buildUniversityTile(String university) {
    final icons = [
      Icons.school,
      Icons.business,
      Icons.account_balance,
      Icons.cast_for_education,
    ];
    final icon = icons[university.hashCode % icons.length];
    final studentCount = 100 + (university.hashCode % 2000);

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 24, color: Colors.white),
      ),
      title: Text(
        university,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$studentCount студентов',
        style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 14, color: AppColors.textDarkSecondary),
      onTap: () => _filterByUniversity(university),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 250),
          delay: Duration(milliseconds: 50),
        );
  }

  // ==================== ВКЛАДКИ УНИВЕРСИТЕТА ====================

  // Студенты университета
  Widget _buildUniversityStudentsTab() {
    return FutureBuilder<List<User>>(
      future: ApiService.instance.getAllUsers(),
      builder: (context, snapshot) {
        List<User> allUsers = snapshot.data ?? [];

        // Фильтруем по университету
        final universityUsers = allUsers.where((u) =>
            (u.university?.toLowerCase() == _selectedUniversity?.toLowerCase()) ?? false).toList();

        if (universityUsers.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
              'Нет студентов',
              'В $_selectedUniversity пока нет студентов',
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildStudentTile(universityUsers[index]),
            childCount: universityUsers.length,
          ),
        );
      },
    );
  }

  // Посты университета
  Widget _buildUniversityPostsTab() {
    final postsAsync = ref.watch(postsStreamProvider);

    return postsAsync.when(
      data: (posts) {
        // Фильтруем по университету автора
        final universityPosts = posts.where((p) =>
            (p.author.university?.toLowerCase() == _selectedUniversity?.toLowerCase()) ?? false).toList();

        if (universityPosts.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
              'Нет постов',
              'В $_selectedUniversity пока нет постов',
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildPostCard(universityPosts[index]),
            childCount: universityPosts.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: _buildEmptyState('Ошибка загрузки', 'Попробуйте позже'),
      ),
    );
  }

  // Проекты университета
  Widget _buildUniversityProjectsTab() {
    final projectsAsync = ref.watch(projectsStreamProvider);

    return projectsAsync.when(
      data: (projects) {
        debugPrint('University projects: total ${projects.length}');
        for (var p in projects) {
          debugPrint('  - Project: ${p.title}, author: ${p.author.name}, university: ${p.author.university}');
        }
        
        // Фильтруем по университету автора
        final universityProjects = projects.where((p) {
          final projectUni = p.author.university?.toLowerCase() ?? '';
          final selectedUni = _selectedUniversity?.toLowerCase() ?? '';
          return projectUni.contains(selectedUni) || selectedUni.contains(projectUni);
        }).toList();

        debugPrint('University projects filtered: ${universityProjects.length}');

        if (universityProjects.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
              'Нет проектов',
              'В $_selectedUniversity пока нет проектов',
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildProjectCard(universityProjects[index]),
            childCount: universityProjects.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: _buildEmptyState('Ошибка загрузки', 'Попробуйте позже'),
      ),
    );
  }

  // Навыки студентов университета
  Widget _buildUniversitySkillsTab() {
    return FutureBuilder<List<User>>(
      future: ApiService.instance.getAllUsers(),
      builder: (context, snapshot) {
        List<User> allUsers = snapshot.data ?? [];

        // Фильтруем по университету
        final universityUsers = allUsers.where((u) =>
            (u.university?.toLowerCase() == _selectedUniversity?.toLowerCase()) ?? false).toList();

        // Собираем все навыки
        final skillCount = <String, int>{};
        for (final user in universityUsers) {
          for (final skill in user.skills) {
            skillCount[skill] = (skillCount[skill] ?? 0) + 1;
          }
        }

        // Сортируем по популярности
        final sortedSkills = skillCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (sortedSkills.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
              'Нет навыков',
              'Студенты $_selectedUniversity ещё не указали навыки',
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final skill = sortedSkills[index].key;
              final count = sortedSkills[index].value;
              return _buildUniversitySkillCard(skill, count, universityUsers.length);
            },
            childCount: sortedSkills.length,
          ),
        );
      },
    );
  }

  Widget _buildUniversitySkillCard(String skill, int count, int totalUsers) {
    final percentage = totalUsers > 0 ? (count / totalUsers * 100).round() : 0;

    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.workspace_premium, size: 24, color: Colors.white),
        ),
        title: Text(
          skill,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count студентов ($percentage%)',
              style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: count / totalUsers,
                backgroundColor: AppColors.surfaceDarkLight,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
          ],
        ),
        onTap: () => _filterBySkill(skill),
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 250),
          delay: Duration(milliseconds: 50),
        );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 60, color: AppColors.textDarkSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
          ),
        ],
      ),
    );
  }
}
