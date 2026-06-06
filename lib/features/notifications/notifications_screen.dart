import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../profile/other_user_profile_screen.dart';
import '../post/post_detail_screen.dart';
import '../project/project_detail_screen.dart';

/// Экран уведомлений
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // В будущем здесь будет реальный API
    // Пока используем моковые данные для демонстрации
    final notifications = _getMockNotifications();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.backgroundDark,
            title: const Text(
              'Уведомления',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (notifications.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 60),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationTile(context, ref, notification, index);
                  },
                  childCount: notifications.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: AppColors.textDarkSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет уведомлений',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут уведомления о новых лайках, комментариях и подписках',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    _Notification notification,
    int index,
  ) {
    return ListTile(
      leading: CustomAvatar(
        radius: 24,
        imageUrl: notification.avatarUrl,
        hasStoryGradient: index < 2,
      ),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          children: [
            TextSpan(
              text: notification.userName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' ${notification.message}'),
          ],
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          notification.timeAgo,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textDarkSecondary,
          ),
        ),
      ),
      trailing: notification.icon != null
          ? Icon(
              notification.icon,
              size: 20,
              color: notification.iconColor,
            )
          : null,
      onTap: () => _handleNotificationTap(context, ref, notification),
    )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 50),
        )
        .slideX(begin: 0.1, end: 0);
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    _Notification notification,
  ) {
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
        // Переход к посту (если есть данные поста)
        if (notification.relatedPost != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: notification.relatedPost!),
            ),
          );
        }
        break;

      case NotificationType.follow:
        // Переход к профилю пользователя
        if (notification.relatedUser != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherUserProfileScreen(user: notification.relatedUser!),
            ),
          );
        }
        break;

      case NotificationType.projectLike:
        // Переход к проекту
        if (notification.relatedProject != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(project: notification.relatedProject!),
            ),
          );
        }
        break;

      default:
        // Для остальных типов показываем уведомление
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Функция в разработке'),
            duration: Duration(seconds: 1),
          ),
        );
    }
  }

  List<_Notification> _getMockNotifications() {
    // В реальном приложении здесь будет API вызов
    // Пока возвращаем пустой список, чтобы показать пустое состояние
    // Можно добавить моковые данные для демонстрации
    return [];
  }
}

enum NotificationType {
  like,
  comment,
  follow,
  projectLike,
  message,
}

class _Notification {
  final String userName;
  final String avatarUrl;
  final String message;
  final String timeAgo;
  final IconData? icon;
  final Color? iconColor;
  final NotificationType type;
  final Post? relatedPost;
  final User? relatedUser;
  final Project? relatedProject;

  const _Notification({
    required this.userName,
    required this.avatarUrl,
    required this.message,
    required this.timeAgo,
    required this.type,
    this.icon,
    this.iconColor,
    this.relatedPost,
    this.relatedUser,
    this.relatedProject,
  });
}
