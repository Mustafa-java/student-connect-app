import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../data/mock/mock_users.dart';
import '../../../data/mock/mock_projects.dart';
import '../../project/project_detail_screen.dart';

/// Горизонтальная лента историй — стиль Instagram 2025
class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 10,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildYourStory(context);
          }

          final user =
              MockUsers.otherUsers[(index - 1) % MockUsers.otherUsers.length];
          final project = MockProjects.projects.length > (index - 1)
              ? MockProjects.projects[index - 1]
              : null;
          return _buildStoryItem(
            context: context,
            name: user.name.split(' ')[0],
            avatarUrl: user.avatarUrl,
            hasUnseen: index <= 5,
            project: project,
          );
        },
      ),
    );
  }

  Widget _buildYourStory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Stack(
            children: [
              const CustomAvatar(
                radius: 30,
                imageUrl: 'https://i.pravatar.cc/300?img=11',
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.backgroundDark,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const SizedBox(
            width: 64,
            child: Text(
              'Ваша история',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textDarkSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem({
    required BuildContext context,
    required String name,
    String? avatarUrl,
    bool hasUnseen = false,
    dynamic project,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          if (project != null) {
            Navigator.push(
              context,
              scaleTransition(ProjectDetailScreen(project: project)),
            );
          }
        },
        child: Column(
          children: [
            CustomAvatar(
              radius: 30,
              imageUrl: avatarUrl,
              hasStoryGradient: hasUnseen,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  color: hasUnseen
                      ? AppColors.textDark
                      : AppColors.textDarkSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
