import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/project_card.dart';
import '../../providers/app_providers.dart';

class MyProjectsScreen extends ConsumerWidget {
  const MyProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Мои проекты'),
        backgroundColor: AppColors.backgroundDark,
        scrolledUnderElevation: 0,
      ),
      body: projectsAsync.when(
        data: (projects) {
          final myProjects =
              projects.where((p) => p.author.id == user?.id).toList();
          if (myProjects.isEmpty)
            return _empty('Проектов пока нет', Icons.folder_open);
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: myProjects.length,
            itemBuilder: (context, index) =>
                ProjectCard(project: myProjects[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            _empty('Не удалось загрузить проекты', Icons.error_outline),
      ),
    );
  }

  Widget _empty(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textDarkSecondary),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: AppColors.textDarkSecondary)),
        ],
      ),
    );
  }
}
