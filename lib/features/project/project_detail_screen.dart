import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:readmore/readmore.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../core/widgets/smart_image.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../common/image_viewer_screen.dart';
import '../common/comments_bottom_sheet.dart';
import '../common/project_download_dialog.dart';
import '../profile/other_user_profile_screen.dart';
import '../messages/chat_screen.dart';
import '../../core/utils/page_transitions.dart';

/// Экран детального просмотра проекта — стиль Instagram 2025 (как PostDetailScreen)
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  late Project _project;
  int _currentImageIndex = 0;
  bool _isLiked = false;
  bool _isSaved = false;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _isLiked = widget.project.isLiked;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _downloadZipFile() async {
    if (!_project.hasZipFile) return;

    final result = await showProjectDownloadDialog(
      context: context,
      projectId: _project.id,
      fileName: _project.zipFileName ?? 'Файл проекта',
      fileSize: _project.zipFileSizeFormatted,
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Файл скачан!'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Сохранён в: /storage/emulated/0/Download/StudentConnect/',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Открыть',
            textColor: Colors.white,
            onPressed: () {
              // Можно открыть файловый менеджер
            },
          ),
        ),
      );
    }
  }

  Future<void> _deleteProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Удалить проект?',
          style: TextStyle(color: AppColors.textDark),
        ),
        content: const Text(
          'Проект будет удалён безвозвратно, включая все файлы и комментарии. Это действие нельзя отменить.',
          style: TextStyle(color: AppColors.textDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ApiService.instance.deleteProject(_project.id);
      
      if (success && mounted) {
        Navigator.of(context).pop(); // Возвращаемся назад
        
        // Показываем сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Проект удалён'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Обновляем список проектов
        final ref = ProviderScope.containerOf(context, listen: false);
        ref.invalidate(projectsStreamProvider);
      } else if (mounted) {
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

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Добавляем комментарий через API
    ref.read(projectCommentsProvider(widget.project.id).notifier).addComment(text);

    _commentController.clear();

    // Скролл вниз
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    final author = project.author;
    final images = project.images;
    final comments = ref.watch(projectCommentsProvider(project.id));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // Sliver AppBar с изображением
          _buildSliverAppBar(images),

          // Контент
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с информацией о проекте
                _buildProjectHeader(author, project),

                const SizedBox(height: 16),

                // Кнопки действий
                _buildActionButtons(project),

                const SizedBox(height: 20),

                // Описание проекта
                if (project.description.isNotEmpty)
                  _buildDescriptionSection(project.description),

                const SizedBox(height: 16),

                // Технологии/навыки
                if (project.skills.isNotEmpty)
                  _buildSkillsSection(project.skills),

                const SizedBox(height: 16),

                // Университеты
                if (project.universityTags.isNotEmpty)
                  _buildUniversitySection(project.universityTags),

                const SizedBox(height: 20),

                // Кнопка скачивания ZIP файла
                if (_project.hasZipFile)
                  _buildDownloadButton(),

                const SizedBox(height: 20),

                // Команда проекта
                if (project.teamMembers.isNotEmpty)
                  _buildTeamSection(),

                const SizedBox(height: 24),

                // Разделитель
                const Divider(height: 1),

                const SizedBox(height: 16),

                // Комментарии
                _buildCommentsSection(comments),

                const SizedBox(height: 100), // Отступ для поля ввода
              ],
            ),
          ),
        ],
      ),

      // Поле ввода комментария (fixed внизу)
      bottomSheet: _buildInputArea(),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  // ==================== НОВЫЕ МЕТОДЫ ДЛЯ РЕДИЗАЙНА ====================

  Widget _buildSliverAppBar(List<String> images) {
    return SliverAppBar(
      expandedHeight: 400,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: Colors.white,
      actions: [
        Consumer(
          builder: (context, ref, child) {
            return IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_horiz, color: Colors.white),
              ),
              onPressed: () => _showOptionsMenu(),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: images.isNotEmpty
            ? _buildImagesCarousel(images)
            : Container(
                color: AppColors.surfaceDark,
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 80,
                    color: AppColors.textDarkSecondary,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProjectHeader(User author, Project project) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Автор и статус
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final currentUser = ref.read(currentUserProvider);
                  final isMyProject =
                      currentUser != null && author.id == currentUser.id;
                  if (isMyProject) {
                    Navigator.pop(context);
                  } else {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            OtherUserProfileScreen(user: author),
                        transitionsBuilder:
                            (context, value, secondaryAnimation, child) {
                          return FadeTransition(opacity: value, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    CustomAvatar(
                      radius: 20,
                      imageUrl: author.avatarUrl,
                      hasStoryGradient: true,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (author.university != null)
                          Text(
                            author.university!,
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
              const Spacer(),
              // Бейдж статуса
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(project.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(project.status).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  project.statusRu,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(project.status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Название проекта
          Text(
            project.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          // Статистика
          Row(
            children: [
              _buildStatItem(Icons.favorite_rounded, project.likesCount.toString(), AppColors.error),
              const SizedBox(width: 16),
              _buildStatItem(Icons.chat_bubble_rounded, project.commentsCount.toString(), AppColors.textDarkSecondary),
              const SizedBox(width: 16),
              _buildStatItem(Icons.visibility_rounded, project.viewsCount.toString(), AppColors.textDarkSecondary),
              const Spacer(),
              Text(
                _getTimeAgo(project.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textDarkSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'idea':
        return const Color(0xFFF59E0B);
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF22C55E);
      case 'looking_for_team':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.textDarkSecondary;
    }
  }

  Widget _buildCommentItem(Comment comment, int index) {
    final currentUser = ref.read(currentUserProvider);
    final isOwnComment = currentUser != null && comment.author.id == currentUser.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomAvatar(
            radius: 16,
            imageUrl: comment.author.avatarUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getTimeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textDarkSecondary,
                      ),
                    ),
                    if (isOwnComment) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Вы',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(projectCommentsProvider(widget.project.id).notifier)
                            .toggleLike(index);
                      },
                      child: Row(
                        children: [
                          Icon(
                            comment.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 14,
                            color: comment.isLiked
                                ? AppColors.error
                                : AppColors.textDarkSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            comment.likesCount > 0
                                ? '${comment.likesCount}'
                                : 'Нравится',
                            style: TextStyle(
                              fontSize: 11,
                              color: comment.isLiked
                                  ? AppColors.error
                                  : AppColors.textDarkSecondary,
                              fontWeight: comment.isLiked
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isOwnComment)
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.surfaceDark,
                              title: const Text(
                                'Удалить комментарий?',
                                style: TextStyle(color: AppColors.textDark),
                              ),
                              content: const Text(
                                'Комментарий будет удалён безвозвратно.',
                                style: TextStyle(color: AppColors.textDarkSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Отмена'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            ref
                                .read(projectCommentsProvider(widget.project.id).notifier)
                                .deleteComment(index);
                          }
                        },
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppColors.textDarkSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 250),
          delay: Duration(milliseconds: index * 30),
        );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            CustomAvatar(
              radius: 16,
              imageUrl: ref.watch(currentUserProvider)?.avatarUrl,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Добавить комментарий...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendComment,
              child: AnimatedOpacity(
                opacity: _commentController.text.trim().isEmpty ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(User author, Project project) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          bottom: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                final currentUser = ref.read(currentUserProvider);
                final isMyProject =
                    currentUser != null && author.id == currentUser.id;
                if (isMyProject) {
                  Navigator.pop(context);
                } else {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          OtherUserProfileScreen(user: author),
                      transitionsBuilder:
                          (context, value, secondaryAnimation, child) {
                        return FadeTransition(opacity: value, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                }
              },
              child: CustomAvatar(
                radius: 16,
                imageUrl: author.avatarUrl,
                hasStoryGradient: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final currentUser = ref.read(currentUserProvider);
                  final isMyProject =
                      currentUser != null && author.id == currentUser.id;
                  if (!isMyProject) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            OtherUserProfileScreen(user: author),
                        transitionsBuilder:
                            (context, value, secondaryAnimation, child) {
                          return FadeTransition(opacity: value, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          author.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (author.isOnline) ...[
                          const SizedBox(width: 5),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (author.university != null)
                      Text(
                        author.university!,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textDarkSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            // Статус проекта (текстом)
            Text(
              project.statusRu,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDarkSecondary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () => _showOptionsMenu(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesCarousel(List<String> images) {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 400,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() => _currentImageIndex = index);
            },
          ),
          carouselController: _carouselController,
          items: images.map((imageUrl) {
            final isLocalFile =
                imageUrl.startsWith('/') || imageUrl.startsWith('file://');
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewerScreen(
                      imageUrls: images,
                      initialIndex: _currentImageIndex,
                    ),
                  ),
                );
              },
              child: Container(
                color: AppColors.backgroundDark,
                child: isLocalFile
                    ? Image.file(
                        File(imageUrl.startsWith('file://')
                            ? imageUrl.replaceFirst('file://', '')
                            : imageUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 50,
                            ),
                          );
                        },
                      )
                    : SmartImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            );
          }).toList(),
        ),
        // Индикатор страниц
        if (images.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(Project project) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final wasLiked = _isLiked;
              setState(() => _isLiked = !_isLiked);
              try {
                final result = await ApiService.instance.toggleProjectLike(_project.id);
                if (mounted) {
                  setState(() {
                    _isLiked = result['is_liked'] as bool;
                    _project = _project.copyWith(
                      likesCount: result['likes_count'] as int,
                    );
                  });
                }
              } catch (e) {
                debugPrint('toggleProjectLike error: $e');
                if (mounted) {
                  setState(() => _isLiked = wasLiked);
                }
              }
            },
            child: AnimatedScale(
              scale: _isLiked ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                size: 26,
                color: _isLiked ? AppColors.error : AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.send_outlined, size: 26, color: AppColors.textDark),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _isSaved = !_isSaved),
            child: AnimatedScale(
              scale: _isSaved ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 26,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Команда проекта',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.project.teamMembers.map((member) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CustomAvatar(
                    radius: 20,
                    imageUrl: member.avatarUrl,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (member.university != null)
                          Text(
                            member.university!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDarkSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_outlined, size: 22),
                    color: AppColors.primary,
                    onPressed: () => _openChatWithAuthor(context, ref),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== НОВЫЕ МЕТОДЫ ДЛЯ РЕДИЗАЙНА ====================

  Widget _buildDescriptionSection(String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Описание',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ReadMoreText(
            description,
            trimLines: 4,
            colorClickableText: AppColors.primary,
            trimMode: TrimMode.Line,
            trimCollapsedText: 'Читать далее',
            trimExpandedText: 'Свернуть',
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textDark,
            ),
            moreStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            lessStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(List<String> skills) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Технологии и навыки',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.accent.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUniversitySection(List<String> universities) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Университеты',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: universities.map((uni) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 14,
                      color: AppColors.textDarkSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      uni,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textDarkSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Файлы проекта',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _downloadZipFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF818CF8),
                      Color(0xFF06B6D4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Скачать проект',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_project.zipFileName ?? 'ZIP файл'} • ${_project.zipFileSizeFormatted}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(List<Comment> comments) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Комментарии',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${comments.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (comments.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 56,
                    color: AppColors.textDarkSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Пока нет комментариев',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Будьте первым!',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textDarkSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildCommentItem(comments[index], index);
              },
            ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    // Получаем currentUser напрямую из ref
    final currentUser = ref.read(currentUserProvider);
    final isMyProject = currentUser != null && widget.project.author.id == currentUser.id;

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
            if (isMyProject)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text(
                  'Удалить проект',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProject();
                },
              ),
            _buildMenuItem(Icons.flag_outlined, 'Пожаловаться'),
            _buildMenuItem(Icons.person_remove_outlined, 'Отписаться'),
            ListTile(
              leading: const Icon(Icons.share_outlined, size: 22),
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                _shareProject();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      onTap: () => Navigator.pop(context),
    );
  }

  void _shareProject() {
    final descriptionPreview = _project.description.length > 150
        ? '${_project.description.substring(0, 150)}...'
        : _project.description;

    final skills = _project.skills.take(5).join(', ');

    final shareText = '''
Посмотри проект в Student Connect!

📌 ${_project.title}

Автор: ${_project.author.name}

$descriptionPreview

Технологии: $skills

👍 ${_project.likesCount} | 💬 ${_project.commentsCount} | 👁 ${_project.viewsCount}
''';

    Share.share(shareText, subject: _project.title);
  }

  /// Универсальный парсер timestamp
  DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
      final dateTime = DateTime.tryParse(value);
      if (dateTime != null) return dateTime;
    }
    return DateTime.now();
  }

  DateTime? _parseTimestampNullable(dynamic value) {
    if (value == null) return null;
    return _parseTimestamp(value);
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inHours < 1) return '${diff.inMinutes} мин.';
    if (diff.inDays < 1) return '${diff.inHours} ч.';
    if (diff.inDays < 7) return '${diff.inDays} дн.';
    return '${dateTime.day} ${_monthName(dateTime.month)} ${dateTime.year}';
  }

  String _monthName(int m) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return months[m - 1];
  }

  Future<void> _openChatWithAuthor(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Не открываем чат с самим собой
    if (widget.project.author.id == currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Это ваш проект'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Создаём или получаем существующий чат
      final chatId = await ApiService.instance.createChat(widget.project.author.id);
      final chats = await ApiService.instance.getChats();
      final chatData = chats.firstWhere(
        (c) => c['id'] == chatId,
        orElse: () => <String, dynamic>{},
      );

      if (chatData.isNotEmpty && context.mounted) {
        final chat = Chat(
          id: chatData['id'] as String,
          currentUser: widget.project.author,
          unreadCount: chatData['unread_count'] as int? ?? 0,
          isOnline: (chatData['is_online'] as int?) == 1,
          lastMessageAt: _parseTimestampNullable(chatData['last_message_at']),
          createdAt: _parseTimestamp(chatData['created_at']),
        );

        Navigator.push(
          context,
          slideTransition(ChatScreen(chat: chat)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка открытия чата: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
