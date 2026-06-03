import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../core/widgets/smart_image.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../common/image_viewer_screen.dart';
import '../common/share_to_chat_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/other_user_profile_screen.dart';

/// Провайдер комментариев для постов
final postCommentsDetailProvider =
    StateNotifierProvider.family<PostCommentsDetailNotifier, List<Comment>, String>(
  (ref, postId) {
    return PostCommentsDetailNotifier(postId);
  },
);

class PostCommentsDetailNotifier extends StateNotifier<List<Comment>> {
  final String postId;

  PostCommentsDetailNotifier(this.postId) : super([]) {
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await ApiService.instance.getComments(postId);
      state = comments;
    } catch (e) {
      debugPrint('PostCommentsDetailNotifier load error: $e');
    }
  }

  Future<void> addComment(String content, User author) async {
    try {
      final comment = await ApiService.instance.addComment(
        postId: postId, content: content,
      );
      state = [...state, comment];
    } catch (e) {
      debugPrint('addComment error: $e');
    }
  }

  Future<void> toggleLike(int index) async {
    final comments = List<Comment>.from(state);
    final comment = comments[index];
    comments[index] = comment.copyWith(
      isLiked: !comment.isLiked,
      likesCount: comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1,
    );
    state = comments;
    // TODO: API для лайков комментариев пока нет
  }

  Future<void> deleteComment(int index) async {
    state = [...state]..removeAt(index);
    // TODO: API для удаления комментариев пока нет
  }
}

/// Экран детального просмотра поста — стиль Instagram 2025
class PostDetailScreen extends ConsumerStatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  int _currentImageIndex = 0;
  bool _isLiked = false;
  bool _isSaved = false;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    ref.read(postCommentsDetailProvider(widget.post.id).notifier).addComment(text, currentUser);

    _commentController.clear();

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

  void _navigateToProfile(User author) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && author.id == currentUser.id) {
      // Переход к своему профилю
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      // Переход к чужому профилю
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OtherUserProfileScreen(user: author)),
      );
    }
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
    final contentPreview = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;

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
        ),
      ),
    );
  }

  void _shareExternal() {
    final content = widget.post.content ?? '';
    final contentPreview = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;

    final shareText = '''
Посмотри пост в Student Connect!

Автор: ${widget.post.author.name}
${contentPreview.isNotEmpty ? '\n$contentPreview' : ''}

Лайков: ${widget.post.likesCount} | Комментариев: ${widget.post.commentsCount}
''';

    Share.share(shareText, subject: 'Пост от ${widget.post.author.name}');
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final author = post.author;
    final images = post.images.map((e) => e.toString()).toList();
    final comments = ref.watch(postCommentsDetailProvider(post.id));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // Верхняя панель
          _buildTopBar(author),

          // Контент
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Изображение (карусель)
                if (images.isNotEmpty)
                  SliverToBoxAdapter(child: _buildImagesCarousel(images)),

                // Действия (лайк, поделиться, сохранить) — БЕЗ кнопки коммента
                SliverToBoxAdapter(child: _buildActionButtons(post)),

                // Лайки
                if (post.likesCount + (_isLiked ? 1 : 0) > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Нравится: ${author.name} и ещё ${post.likesCount + (_isLiked ? 1 : 0) - 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Описание
                if (post.content != null && post.content!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textDark),
                          children: [
                            TextSpan(
                              text: '${author.name}  ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: post.content),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Теги
                if (post.tags.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Wrap(
                        spacing: 6,
                        children: post.tags
                            .map((tag) => _buildChip('#$tag'))
                            .toList(),
                      ),
                    ),
                  ),

                // Время
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      _getTimeAgo(post.createdAt).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textDarkSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Разделитель
                const SliverToBoxAdapter(
                  child: Divider(height: 1),
                ),

                // Комментарии
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Комментарии (${comments.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (comments.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: AppColors.textDarkSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Пока нет комментариев',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textDarkSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Будьте первым!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textDarkSecondary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              return _buildCommentItem(comments[index], index);
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          // Поле ввода комментария (внизу экрана)
          _buildInputArea(),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
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
                            .read(postCommentsDetailProvider(widget.post.id).notifier)
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
                        onTap: () {
                          ref
                              .read(postCommentsDetailProvider(widget.post.id).notifier)
                              .deleteComment(index);
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

  Widget _buildTopBar(User author) {
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
              onTap: () => _navigateToProfile(author),
              child: CustomAvatar(radius: 16, imageUrl: author.avatarUrl, hasStoryGradient: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _navigateToProfile(author),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (author.university != null)
                      Text(
                        author.university!,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textDarkSecondary),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {},
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

  Widget _buildActionButtons(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isLiked = !_isLiked),
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
          GestureDetector(
            onTap: _sharePost,
            child: Icon(Icons.send_outlined, size: 26, color: AppColors.textDark),
          ),
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

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary)),
    );
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
}
