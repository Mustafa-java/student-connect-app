import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Skeleton загрузка для карточки проекта
class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с аватаром
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildCircleSkeleton(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLineSkeleton(width: 120),
                      const SizedBox(height: 6),
                      _buildLineSkeleton(width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Изображение
          Shimmer.fromColors(
            baseColor: AppColors.skeleton,
            highlightColor: AppColors.skeletonHighlight,
            child: Container(
              height: 250,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
          // Контент
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLineSkeleton(width: 180),
                const SizedBox(height: 8),
                _buildLineSkeleton(width: double.infinity),
                const SizedBox(height: 6),
                _buildLineSkeleton(width: 200),
                const SizedBox(height: 12),
                // Chips
                Row(
                  children: [
                    _buildChipSkeleton(),
                    const SizedBox(width: 8),
                    _buildChipSkeleton(),
                    const SizedBox(width: 8),
                    _buildChipSkeleton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.skeleton,
      highlightColor: AppColors.skeletonHighlight,
      child: const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildLineSkeleton({double width = 100, double height = 14}) {
    return Shimmer.fromColors(
      baseColor: AppColors.skeleton,
      highlightColor: AppColors.skeletonHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildChipSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.skeleton,
      highlightColor: AppColors.skeletonHighlight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          '       ',
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

/// Skeleton для истории (stories)
class StorySkeleton extends StatelessWidget {
  const StorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.skeleton,
      highlightColor: AppColors.skeletonHighlight,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
            ),
            SizedBox(height: 6),
            SizedBox(
              width: 50,
              height: 12,
              child: const Placeholder(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton для списка сообщений
class MessageListSkeleton extends StatelessWidget {
  const MessageListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: AppColors.skeleton,
                highlightColor: AppColors.skeletonHighlight,
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: AppColors.skeleton,
                      highlightColor: AppColors.skeletonHighlight,
                      child: Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: AppColors.skeleton,
                      highlightColor: AppColors.skeletonHighlight,
                      child: Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton для сетки проектов в профиле
class ProfileGridSkeleton extends StatelessWidget {
  const ProfileGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.skeleton,
          highlightColor: AppColors.skeletonHighlight,
          child: Container(
            color: Colors.white,
          ),
        );
      },
    );
  }
}
