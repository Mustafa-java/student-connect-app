import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final achievements = [
      _Achievement(
          'Первый профиль', 'Профиль создан', Icons.person_rounded, true),
      _Achievement('Проектный старт', 'Создайте первый проект',
          Icons.folder_rounded, (user?.projectsCount ?? 0) > 0),
      _Achievement('Социальный студент', 'Получите первую подписку',
          Icons.people_rounded, (user?.followersCount ?? 0) > 0),
      _Achievement('Набор навыков', 'Добавьте 3+ навыка',
          Icons.workspace_premium_rounded, (user?.skills.length ?? 0) >= 3),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Достижения'),
        backgroundColor: AppColors.backgroundDark,
        scrolledUnderElevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = achievements[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.unlocked
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: item.unlocked
                      ? AppColors.primary
                      : AppColors.surfaceDarkLight,
                  child: Icon(item.icon,
                      color: item.unlocked
                          ? Colors.white
                          : AppColors.textDarkSecondary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(item.subtitle,
                          style: TextStyle(
                              color: AppColors.textDarkSecondary,
                              fontSize: 12)),
                    ],
                  ),
                ),
                Icon(item.unlocked ? Icons.check_circle : Icons.lock_outline,
                    color: item.unlocked
                        ? AppColors.success
                        : AppColors.textDarkSecondary),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool unlocked;

  _Achievement(this.title, this.subtitle, this.icon, this.unlocked);
}
