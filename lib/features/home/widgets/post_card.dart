import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:readmore/readmore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/widgets/smart_image.dart';
import '../../../core/widgets/post_video_player.dart';
import '../../../features/common/image_viewer_screen.dart';
import '../../../features/common/comments_bottom_sheet.dart';
import '../../../features/common/share_to_chat_screen.dart';
import '../../../features/profile/other_user_profile_screen.dart';
import '../../../features/profile/profile_screen.dart';
import '../../../providers/app_providers.dart';
import '../../../models/models.dart';
import '../../../services/api_service.dart';

/// Карточка поста в ленте — стиль Instagram 2025
class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  bool _showHeartAnimation = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.post.isSaved;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final author = post.author;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок поста
          _buildHeader(author),

          // Изображения (карусель)
          if (post.images.isNotEmpty || post.project?.images.isNotEmpty == true || (post.videoUrl != null && post.videoUrl!.isNotEmpty))
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: Stack(
                children: [
                  _buildImagesCarousel(post),
                  // Анимация сердца при double-tap
                  if (_showHeartAnimation)
                    Center(
                      child: Icon(
                        Icons.favorite,
                        size: 80,
                        color: Colors.white,
                      )
                          .animate(
                            onPlay: (controller) => controller.repeat(),
                          )
                          .scale(
                            begin: const Offset(0, 0),
                            end: const Offset(1.5, 1.5),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          )
                          .then()
                          .fade(
                            begin: 1,
                            end: 0,
                            duration: const Duration(milliseconds: 400),
                          ),
                    ),
                ],
              ),
            ),

          // Кнопки действий
          _buildActionButtons(post),

          // Контент
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Likes
                Consumer(
                  builder: (context, ref, _) {
                    final likesState =
                        ref.watch(postLikesProvider(widget.post.id));
                    final totalLikes = widget.post.likesCount +
                        (likesState.isLikedByCurrentUser ? 1 : 0) -
                        (widget.post.isLiked ? 1 : 0);
                    if (totalLikes > 0)
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Нравится: ${_getLikesText(totalLikes)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      );
                    return const SizedBox.shrink();
                  },
                ),

                // Описание проекта или контент поста
                if (post.project != null) ...[
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${author.name}  ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextSpan(
                          text: post.project!.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                if (post.content != null && post.content!.isNotEmpty)
                  ReadMoreText(
                    post.content!,
                    trimLines: 2,
                    colorClickableText: AppColors.textDarkSecondary,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: 'ещё',
                    trimExpandedText: 'свернуть',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                    moreStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDarkSecondary,
                    ),
                    lessStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),

                // Кнопка комментариев
                if (post.commentsCount > 0)
                  GestureDetector(
                    onTap: () => _openComments(context),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Посмотреть все комментарии (${post.commentsCount})',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textDarkSecondary,
                        ),
                      ),
                    ),
                  ),

                // Теги/навыки
                if (post.tags.isNotEmpty ||
                    (post.project?.skills.isNotEmpty == true))
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...post.tags.map((tag) => _buildChip('#$tag')),
                        if (post.project != null)
                          ...post.project!.skills
                              .take(3)
                              .map((skill) => _buildChip(skill, isSkill: true)),
                      ],
                    ),
                  ),

                // Время публикации
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  child: Text(
                    _getTimeAgo(post.createdAt).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ),

                // Кнопка просмотра проекта
                if (post.project != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.onTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Просмотреть проект',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(
          begin: 0.05,
          end: 0,
          duration: const Duration(milliseconds: 300),
        );
  }

  Widget _buildHeader(User author) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Consumer(
            builder: (context, ref, _) {
              final currentUser = ref.watch(currentUserProvider);
              final isMyPost =
                  currentUser != null && author.id == currentUser.id;
              return CustomAvatar(
                radius: 16,
                imageUrl: author.avatarUrl,
                hasStoryGradient: true,
                onTap: () {
                  if (isMyPost) {
                    // Переходим на МОЙ профиль
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const ProfileScreen(),
                        transitionsBuilder:
                            (context, value, secondaryAnimation, child) {
                          return FadeTransition(opacity: value, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  } else {
                    // Переходим к ЧУЖОМУ профилю
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
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final currentUser = ref.watch(currentUserProvider);
                        final isMyPost =
                            currentUser != null && author.id == currentUser.id;
                        return GestureDetector(
                          onTap: () {
                            if (isMyPost) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const ProfileScreen(),
                                  transitionsBuilder: (context, value,
                                      secondaryAnimation, child) {
                                    return FadeTransition(
                                        opacity: value, child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                ),
                              );
                            } else {
                              // Переходим к ЧУЖОМУ профилю
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      OtherUserProfileScreen(user: author),
                                  transitionsBuilder: (context, value,
                                      secondaryAnimation, child) {
                                    return FadeTransition(
                                        opacity: value, child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                ),
                              );
                            }
                          },
                          child: Text(
                            author.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        );
                      },
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
                      fontSize: 11,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(currentUserProvider);
              final isMyPost =
                  currentUser != null && author.id == currentUser.id;
              return IconButton(
                icon: const Icon(Icons.more_horiz, size: 20),
                onPressed: () => _showOptionsMenu(currentUser),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImagesCarousel(Post post) {
    final images =
        post.images.isNotEmpty ? post.images : post.project?.images ?? [];
    final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;

    if (images.isEmpty && !hasVideo) return const SizedBox.shrink();

    return Column(
      children: [
        if (hasVideo)
          PostVideoPlayer(videoUrl: post.videoUrl!),
        if (images.isNotEmpty)
          CarouselSlider(
            options: CarouselOptions(
              height: 350,
              viewportFraction: 1.0,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
            ),
            carouselController: _carouselController,
            items: images.map((imageUrl) {
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
                  color: AppColors.surfaceDark,
                  child: SmartImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }).toList(),
          ),

        // Индикатор страниц
        if (images.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: _currentImageIndex == index ? 8 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _currentImageIndex == index
                      ? AppColors.primary
                      : AppColors.textDarkSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildActionButtons(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Consumer(
        builder: (context, ref, _) {
          final currentUser = ref.watch(currentUserProvider);
          final likesState = ref.watch(postLikesProvider(post.id));

          return Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (currentUser == null) return;
                  ref
                      .read(postLikesProvider(post.id).notifier)
                      .toggleLike(currentUser.id);
                  setState(() {
                    _showHeartAnimation = true;
                  });
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) {
                      setState(() {
                        _showHeartAnimation = false;
                      });
                    }
                  });
                },
                child: AnimatedScale(
                  scale: likesState.isLikedByCurrentUser ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: Icon(
                    likesState.isLikedByCurrentUser
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 24,
                    color: likesState.isLikedByCurrentUser
                        ? AppColors.error
                        : AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _openComments(context),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 24,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sharePost,
                child: Icon(
                  Icons.send_outlined,
                  size: 24,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final saved =
                      await ApiService.instance.toggleSavePost(widget.post.id);
                  if (mounted) setState(() => _isSaved = saved);
                },
                child: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  size: 24,
                  color: AppColors.textDark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, {bool isSkill = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSkill
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSkill ? AppColors.primary : AppColors.textDarkSecondary,
          fontWeight: isSkill ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _editPost() async {
    final contentController = TextEditingController(text: widget.post.content);
    final tagsController =
        TextEditingController(text: widget.post.tags.join(', '));

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Редактировать пост',
            style: TextStyle(color: AppColors.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentController,
              maxLines: 5,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Текст поста',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tagsController,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Теги (через запятую)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final tags = tagsController.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
              Navigator.pop(context, {
                'content': contentController.text,
                'tags': tags,
              });
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await ApiService.instance.updatePost(
          postId: widget.post.id,
          content: result['content'],
          tags: result['tags'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Пост обновлён'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          final ref = ProviderScope.containerOf(context, listen: false);
          ref.invalidate(postsStreamProvider);
          ref.invalidate(followingPostsStreamProvider);
          ref.invalidate(postsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось обновить пост'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Удалить пост?',
          style: TextStyle(color: AppColors.textDark),
        ),
        content: const Text(
          'Пост будет удалён безвозвратно. Это действие нельзя отменить.',
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
      final success = await ApiService.instance.deletePost(widget.post.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пост удалён'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Обновляем ленту
        if (mounted) {
          final ref = ProviderScope.containerOf(context, listen: false);
          ref.invalidate(postsStreamProvider);
          ref.invalidate(followingPostsStreamProvider);
          ref.invalidate(postsProvider);
        }
      } else if (mounted) {
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

  void _handleDoubleTap() {
    // Double-tap to like — handled by Consumer in _buildActionButtons
    setState(() {
      _showHeartAnimation = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        postId: widget.post.id,
        postAuthorName: widget.post.author.name,
      ),
    );
  }

  void _showOptionsMenu(User? currentUser) {
    final isMyPost =
        currentUser != null && widget.post.author.id == currentUser.id;

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
            if (isMyPost)
              ListTile(
                leading:
                    const Icon(Icons.edit_outlined, color: AppColors.primary),
                title: const Text('Редактировать'),
                onTap: () {
                  Navigator.pop(context);
                  _editPost();
                },
              ),
            if (isMyPost)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text(
                  'Удалить',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost();
                },
              ),
            _buildMenuItem(Icons.flag_outlined, 'Пожаловаться'),
            _buildMenuItem(Icons.person_remove_outlined, 'Отписаться'),
            ListTile(
              leading: const Icon(Icons.share_outlined, size: 22),
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                _sharePost();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _sharePost() {
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
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Отправить в чате'),
              onTap: () {
                Navigator.pop(context);
                _shareInApp();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Поделиться вне приложения'),
              onTap: () {
                Navigator.pop(context);
                _shareExternal();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _shareInApp() {
    final content = widget.post.content ?? '';
    final contentPreview =
        content.length > 100 ? '${content.substring(0, 100)}...' : content;

    final shareText = '''
📝 Пост от ${widget.post.author.name}

${contentPreview.isNotEmpty ? contentPreview : 'Без текста'}

👍 ${widget.post.likesCount} | 💬 ${widget.post.commentsCount}
''';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareToChatScreen(
          shareText: shareText,
          shareTitle: 'Пост от ${widget.post.author.name}',
          messageType: 'post',
          postId: widget.post.id,
        ),
      ),
    );
  }

  void _shareExternal() {
    final content = widget.post.content ?? '';
    final contentPreview =
        content.length > 100 ? '${content.substring(0, 100)}...' : content;

    final shareText = '''
Посмотри пост в Student Connect!

Автор: ${widget.post.author.name}
${contentPreview.isNotEmpty ? '\n$contentPreview' : ''}

Лайков: ${widget.post.likesCount} | Комментариев: ${widget.post.commentsCount}
''';

    Share.share(shareText, subject: 'Пост от ${widget.post.author.name}');
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      onTap: () => Navigator.pop(context),
    );
  }

  String _getLikesText(int totalLikes) {
    if (totalLikes == 0) return '';
    if (totalLikes == 1) return widget.post.author.name;
    return '${widget.post.author.name} и ещё $totalLikes';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'только что';
    if (diff.inHours < 1) return '${diff.inMinutes} мин.';
    if (diff.inDays < 1) return '${diff.inHours} ч.';
    if (diff.inDays < 7) return '${diff.inDays} дн.';
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }
}
