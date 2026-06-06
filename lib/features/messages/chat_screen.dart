import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../post/post_detail_screen.dart';
import '../project/project_detail_screen.dart';

/// Экран чата — стиль Instagram 2025
class ChatScreen extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatScreen({
    super.key,
    required this.chat,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    // Отмечаем сообщения как прочитанные при открытии чата
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  Future<void> _markAsRead() async {
    if (_hasMarkedAsRead) return;
    _hasMarkedAsRead = true;
    try {
      await ApiService.instance.markChatAsRead(widget.chat.id);
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      final messageData = await ApiService.instance.sendMessage(
        chatId: widget.chat.id,
        content: content,
      );

      // Логируем успешную отправку
      debugPrint('Message sent successfully: ${messageData['id']}');
    } catch (e, stackTrace) {
      debugPrint('sendMessage error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки сообщения: ${e.toString()}'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Повторить',
              textColor: Colors.white,
              onPressed: () {
                _messageController.text = content;
                _sendMessage();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.chat.currentUser;
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chat.id));
    final currentUser = ref.watch(currentUserProvider);
    final isGroup = widget.chat.isGroup;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            isGroup
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.groups_rounded,
                        size: 18, color: Colors.white),
                  )
                : AvatarWithOnlineIndicator(
                    imageUrl: user.avatarUrl,
                    radius: 16,
                    isOnline: widget.chat.isOnline,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.displayTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isGroup
                        ? '${widget.chat.participantsCount} участников'
                        : (widget.chat.isOnline ? 'Онлайн' : 'Был(а) недавно'),
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.chat.isOnline && !isGroup
                          ? AppColors.success
                          : AppColors.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isGroup)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showGroupInfo,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.phone_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              onPressed: () {},
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Сообщения
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 60,
                          color: AppColors.textDarkSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Начните общение',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = currentUser != null &&
                        message.sender.id == currentUser.id;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) {
                debugPrint('ChatScreen messages error: $error');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 60,
                        color: AppColors.textDarkSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Нет сообщений',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Поле ввода
          _buildInputArea(),
        ],
      ),
    );
  }

  void _showGroupInfo() {
    final currentUser = ref.read(currentUserProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FutureBuilder<Map<String, dynamic>?>(
        future: ApiService.instance.getTeamByChat(widget.chat.id),
        builder: (context, snapshot) {
          final team = snapshot.data;
          final teamId = team?['id']?.toString();
          final creatorId = team?['creator_id']?.toString();
          final isCreator = currentUser != null && creatorId == currentUser.id;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.groups_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.chat.displayTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.chat.participantsCount} участников',
                    style: const TextStyle(color: AppColors.textDarkSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (teamId != null)
                    _memberList(
                        teamId: teamId,
                        isCreator: isCreator,
                        currentUser: currentUser),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _memberList({
    required String teamId,
    required bool isCreator,
    required User? currentUser,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService.instance.getTeamMembers(teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final members = snapshot.data ?? [];
        if (members.isEmpty) return const SizedBox.shrink();

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 300),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: members.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) {
              final member = members[index];
              final memberId = member['id']?.toString() ?? '';
              final name = member['name']?.toString() ?? 'Пользователь';
              final avatarUrl = member['avatar_url']?.toString();
              final canRemove = isCreator && memberId != currentUser?.id;

              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                      : null,
                ),
                title: Text(name,
                    style: const TextStyle(color: AppColors.textDark)),
                trailing: canRemove
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.error, size: 20),
                        onPressed: () async {
                          Navigator.pop(context);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surfaceDark,
                              title: const Text('Удалить участника?'),
                              content: Text('Удалить $name из команды?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Отмена'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ApiService.instance
                                .removeTeamMember(teamId, memberId);
                          }
                        },
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    // Для постов и проектов показываем превью
    if (message.type == MessageType.post ||
        message.type == MessageType.project) {
      return _buildSharedContentBubble(message, isMe);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: isMe ? AppColors.primaryGradient : null,
                color: isMe ? null : AppColors.surfaceDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done_outlined,
                          size: 12,
                          color: message.isRead
                              ? AppColors.accent
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedContentBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () => _openSharedContent(message),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  gradient: isMe ? AppColors.primaryGradient : null,
                  color: isMe ? null : AppColors.surfaceDark,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Превью контента
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            message.type == MessageType.post
                                ? Icons.article_outlined
                                : Icons.folder_outlined,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.type == MessageType.post
                                      ? 'Поделился постом'
                                      : 'Поделился проектом',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message.content
                                      .split('\n')
                                      .first
                                      .replaceAll('📝 ', '')
                                      .replaceAll('📌 ', ''),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                    // Время
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatMessageTime(message.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead
                                  ? Icons.done_all
                                  : Icons.done_outlined,
                              size: 12,
                              color: message.isRead
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                          ],
                        ],
                      ),
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

  void _openSharedContent(Message message) async {
    if (message.projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID контента не найден')),
      );
      return;
    }

    debugPrint(
        'Opening shared content: type=${message.type}, id=${message.projectId}');

    try {
      if (message.type == MessageType.post) {
        // Загрузка поста по ID
        debugPrint('Loading posts...');
        final posts = await ApiService.instance.getPosts();
        debugPrint(
            'Loaded ${posts.length} posts, searching for ${message.projectId}');

        final post = posts.firstWhere(
          (p) {
            debugPrint('Checking post: id=${p.id}');
            return p.id == message.projectId;
          },
          orElse: () =>
              throw Exception('Пост не найден (ID: ${message.projectId})'),
        );

        debugPrint('Post found: ${post.id}');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        }
      } else if (message.type == MessageType.project) {
        // Загрузка проекта по ID
        debugPrint('Loading projects...');
        final projects = await ApiService.instance.getProjects();
        debugPrint(
            'Loaded ${projects.length} projects, searching for ${message.projectId}');

        final project = projects.firstWhere(
          (p) => p.id == message.projectId,
          orElse: () => throw Exception('Проект не найден'),
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(project: project),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening shared content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Сообщение...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (messageDate == yesterday) return 'Вчера';

    return '${time.day}.${time.month}';
  }
}
