import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../data/mock/mock_users.dart';

/// Bottom sheet с комментариями — стиль Instagram
class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String postId;
  final String postAuthorName;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.postAuthorName,
  });

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);

    try {
      await ApiService.instance.addComment(
        postId: widget.postId, content: text,
      );
    } catch (e) {
      debugPrint('addComment error: $e');
    } finally {
      _commentController.clear();
      setState(() => _isSending = false);
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(postCommentsProvider(widget.postId));
    final currentUser = ref.watch(currentUserProvider) ?? MockUsers.currentUser;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.textDarkSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Комментарии',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${comments.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Comments list
          Expanded(
            child: comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = comments.length - 1 - index;
                      return _buildCommentItem(
                        comments[reversedIndex],
                        reversedIndex,
                        currentUser,
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          // Input
          _buildInputArea(currentUser),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    Comment comment,
    int index,
    User currentUser,
  ) {
    final isOwnComment = comment.author.id == currentUser.id;
    final timeAgo = _getTimeAgo(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                      timeAgo,
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
                            .read(postCommentsProvider(widget.postId).notifier)
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
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        _commentController.text =
                            '@${comment.author.name.split(' ')[0]} ';
                      },
                      child: Text(
                        'Ответить',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDarkSecondary,
                        ),
                      ),
                    ),
                    if (isOwnComment) ...[
                      const Spacer(),
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
                                .read(
                                    postCommentsProvider(widget.postId).notifier)
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
                  ],
                ),
                // Replies
                if (comment.replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 8),
                    child: Column(
                      children: comment.replies.map((reply) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomAvatar(
                                radius: 12,
                                imageUrl: reply.author.avatarUrl,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          reply.author.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getTimeAgo(reply.createdAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textDarkSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      reply.content,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textDark,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
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

  Widget _buildInputArea(User currentUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
      ),
      child: SafeArea(
        child: Row(
          children: [
            CustomAvatar(
              radius: 16,
              imageUrl: currentUser.avatarUrl,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'сейчас';
    if (diff.inHours < 1) return '${diff.inMinutes} мин.';
    if (diff.inDays < 1) return '${diff.inHours} ч.';
    if (diff.inDays < 7) return '${diff.inDays} дн.';
    return '${dateTime.day}.${dateTime.month}';
  }
}
