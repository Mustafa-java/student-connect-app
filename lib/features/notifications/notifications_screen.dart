import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final notifications = await ApiService.instance.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    }
  }

  Future<void> _handleTeamInvite(
      Map<String, dynamic> notification, bool accept) async {
    final data = notification['data'] as Map<String, dynamic>?;
    if (data == null) return;

    final invitationId = data['invitation_id']?.toString();
    if (invitationId == null) return;

    try {
      if (accept) {
        await ApiService.instance.acceptTeamInvitation(invitationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Вы присоединились к команде'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await ApiService.instance.rejectTeamInvitation(invitationId);
      }
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Ошибка: $e' : 'Отклонено'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    int millis;
    if (createdAt is int) {
      millis = createdAt;
    } else if (createdAt is String) {
      millis = int.tryParse(createdAt) ?? 0;
    } else {
      return '';
    }
    final diff = DateTime.now().millisecondsSinceEpoch - millis;
    final minutes = diff ~/ 60000;
    if (minutes < 1) return 'Только что';
    if (minutes < 60) return '$minutes мин';
    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours ч';
    final days = hours ~/ 24;
    if (days < 7) return '$days дн';
    return '${days ~/ 7} нед';
  }

  @override
  Widget build(BuildContext context) {
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
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_notifications.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 60),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationTile(notification, index);
                  },
                  childCount: _notifications.length,
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
          Icon(Icons.notifications_none_rounded,
              size: 64, color: AppColors.textDarkSecondary),
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
            style: TextStyle(fontSize: 14, color: AppColors.textDarkSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification, int index) {
    final type = notification['type']?.toString() ?? '';
    final data = notification['data'] as Map<String, dynamic>?;

    if (type == 'team_invite') {
      final teamName = data?['team_name']?.toString() ?? 'команду';
      final fromUserName =
          notification['from_user_name']?.toString() ?? 'Пользователь';
      final fromUserAvatar = notification['from_user_avatar']?.toString();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              backgroundImage:
                  fromUserAvatar != null && fromUserAvatar.isNotEmpty
                      ? NetworkImage(fromUserAvatar)
                      : null,
              child: fromUserAvatar == null || fromUserAvatar.isEmpty
                  ? Text(fromUserName.isNotEmpty
                      ? fromUserName[0].toUpperCase()
                      : '?')
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textDark),
                      children: [
                        TextSpan(
                          text: fromUserName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' приглашает вас в команду "$teamName"'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _timeAgo(notification['created_at']),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textDarkSecondary),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _handleTeamInvite(notification, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Вступить',
                            style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: () => _handleTeamInvite(notification, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          side: const BorderSide(
                              color: AppColors.textDarkSecondary),
                        ),
                        child: const Text('Отклонить',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textDarkSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: index * 50),
          )
          .slideX(begin: 0.1, end: 0);
    }

    // Другие типы уведомлений (заглушка)
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.surfaceDark,
        child: Icon(
          type == 'like'
              ? Icons.favorite
              : type == 'comment'
                  ? Icons.comment
                  : Icons.notifications,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        'Уведомление: $type',
        style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      ),
      subtitle: Text(
        _timeAgo(notification['created_at']),
        style:
            const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 50),
        );
  }
}
