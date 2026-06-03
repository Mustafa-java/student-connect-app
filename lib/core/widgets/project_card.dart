import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/smart_image.dart';
import '../../models/models.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/other_user_profile_screen.dart';
import '../../providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Карточка проекта для отображения в ленте и поиске
class ProjectCard extends ConsumerWidget {
  final Project project;
  final VoidCallback? onTap;
  final bool showAuthor;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.showAuthor = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = project.images.isNotEmpty
        ? project.images.first
        : 'https://picsum.photos/seed/${project.id}/300/400';

    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.pushNamed(
              context,
              '/project-detail',
              arguments: project,
            );
          },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение проекта
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Главное изображение
                    SmartImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),

                    // Градиент сверху для статуса
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Статус проекта
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(project.status)
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                project.statusRu,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),

                            // Индикатор количества изображений
                            if (project.images.length > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_library,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${project.images.length}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ZIP файл индикатор
                    if (project.hasZipFile)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF818CF8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.folder_zip_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Информация о проекте
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название проекта
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Автор (опционально)
                      if (showAuthor) ...[
                        GestureDetector(
                          onTap: () {
                            final currentUser = ref.read(currentUserProvider);
                            if (currentUser != null && project.author.id == currentUser.id) {
                              // Переход к своему профилю
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            } else {
                              // Переход к чужому профилю
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherUserProfileScreen(
                                    userId: project.author.id,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: NetworkImage(
                                  (project.author.avatarUrl == null || project.author.avatarUrl!.isEmpty)
                                      ? 'https://ui-avatars.com/api/?name=${project.author.name}&background=6366F1&color=fff'
                                      : project.author.avatarUrl!,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  project.author.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textDarkSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Статистика
                      Row(
                        children: [
                          _buildStatItem(
                            Icons.favorite_rounded,
                            '${project.likesCount}',
                            AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          _buildStatItem(
                            Icons.chat_bubble_rounded,
                            '${project.commentsCount}',
                            AppColors.textDarkSecondary,
                          ),
                          const SizedBox(width: 8),
                          _buildStatItem(
                            Icons.visibility_rounded,
                            '${project.viewsCount}',
                            AppColors.textDarkSecondary,
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Теги навыков
                      if (project.skills.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 20),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: project.skills.take(3).length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  project.skills[index],
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: 50),
        );
  }

  Widget _buildStatItem(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          count,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
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
}
