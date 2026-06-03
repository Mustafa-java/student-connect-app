import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

/// Экран выбора чата для отправки поста/проекта
class ShareToChatScreen extends ConsumerStatefulWidget {
  final String shareText;
  final String shareTitle;

  const ShareToChatScreen({
    super.key,
    required this.shareText,
    required this.shareTitle,
  });

  @override
  ConsumerState<ShareToChatScreen> createState() => _ShareToChatScreenState();
}

class _ShareToChatScreenState extends ConsumerState<ShareToChatScreen> {
  bool _isSending = false;

  Future<void> _sendToChat(Chat chat) async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      await ApiService.instance.sendMessage(
        chatId: chat.id,
        content: widget.shareText,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отправлено!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Отправить в чате'),
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.textDarkSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет чатов',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatTile(chat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Ошибка загрузки чатов')),
      ),
    );
  }

  Widget _buildChatTile(Chat chat) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CustomAvatar(
        radius: 24,
        imageUrl: chat.currentUser.avatarUrl,
      ),
      title: Text(
        chat.currentUser.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: chat.lastMessage != null
          ? Text(
              chat.lastMessage!.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDarkSecondary,
              ),
            )
          : null,
      trailing: _isSending
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.send, color: AppColors.primary),
      onTap: () => _sendToChat(chat),
    );
  }
}
