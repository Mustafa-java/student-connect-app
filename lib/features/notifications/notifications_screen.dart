import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';

/// Экран уведомлений
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = _mockNotifications;

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
                    return _buildNotificationTile(notification, index);
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

  Widget _buildNotificationTile(_Notification notification, int index) {
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
      onTap: () {},
    )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 50),
        )
        .slideX(begin: 0.1, end: 0);
  }
}

class _Notification {
  final String userName;
  final String avatarUrl;
  final String message;
  final String timeAgo;
  final IconData? icon;
  final Color? iconColor;

  const _Notification({
    required this.userName,
    required this.avatarUrl,
    required this.message,
    required this.timeAgo,
    this.icon,
    this.iconColor,
  });
}

final _mockNotifications = <_Notification>[];
