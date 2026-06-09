import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

/// Экран создания проекта — стиль Instagram 2025
class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<XFile> _images = [];
  final Set<String> _selectedSkills = {};
  String _selectedStatus = 'idea';
  bool _isCreating = false;

  // ZIP файл
  File? _zipFile;
  String? _zipFileName;
  int _zipFileSize = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (images.isNotEmpty) {
      setState(() {
        _images.addAll(images.take(5 - _images.length));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _pickZipFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'rar', '7z', 'tar', 'gz'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          if (file.size > AppConstants.maxZipFileSize) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Файл слишком большой (${formatFileSize(file.size)}). '
                    'Максимум ${formatFileSize(AppConstants.maxZipFileSize)}',
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }
          setState(() {
            _zipFile = File(file.path!);
            _zipFileName = file.name;
            _zipFileSize = file.size;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking ZIP file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора файла: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeZipFile() {
    setState(() {
      _zipFile = null;
      _zipFileName = null;
      _zipFileSize = 0;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _createProject() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите название проекта'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите описание проекта'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы один навык'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      // Получаем пути изображений
      final imagePaths = _images.map((img) => img.path).toList();

      // Создаём проект
      final createdProject = await ApiService.instance.createProject(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        images: imagePaths,
        skills: _selectedSkills.toList(),
        status: _selectedStatus,
        universityTags: user.university != null ? [user.university!] : [],
      );

      if (createdProject != null) {
        // Загружаем ZIP файл если выбран
        if (_zipFile != null) {
          try {
            debugPrint('Uploading ZIP file...');
            await ApiService.instance.uploadProjectZip(
              createdProject.id,
              _zipFile!.path,
            );
            debugPrint('ZIP file uploaded successfully');
          } catch (e) {
            debugPrint('ZIP upload error: $e');
            // Не прерываем создание проекта если ZIP не загрузился
          }
        }

        final projects = ref.read(projectsProvider);
        ref.read(projectsProvider.notifier).state = [createdProject, ...projects];

        if (!mounted) return;
        setState(() => _isCreating = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Проект создан! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pop(context);
      } else {
        if (!mounted) return;
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при создании проекта'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text('Новый проект', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createProject,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Опубликовать',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Название
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Название проекта',
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Описание
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Описание проекта...',
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Изображения
          const Text(
            'Фотографии',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._images.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(image.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (_images.length < 5)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 28, color: AppColors.primary),
                          const SizedBox(height: 4),
                          Text(
                            '${_images.length}/5',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textDarkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ZIP файл проекта
          const Text(
            'Файл проекта (ZIP)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_zipFile != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_zip_rounded, size: 28, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_zipFileName ?? 'ZIP файл'} (${formatFileSize(_zipFileSize ?? 0)})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatFileSize(_zipFileSize),
                          style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _removeZipFile,
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _pickZipFile,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Прикрепить ZIP (опционально)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Добавьте ZIP файл с исходным кодом проекта',
            style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
          ),
          const SizedBox(height: 24),

          // Навыки
          const Text(
            'Технологии',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Выбрано: ${_selectedSkills.length}',
            style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.defaultSkills.map((skill) {
              final isSelected = _selectedSkills.contains(skill);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSkills.remove(skill);
                    } else {
                      _selectedSkills.add(skill);
                    }
                  });
                },
                child: Chip(
                  label: Text(skill),
                  backgroundColor: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.surfaceDark,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Статус
          const Text(
            'Статус проекта',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'idea', child: Text('Идея')),
              DropdownMenuItem(value: 'in_progress', child: Text('В разработке')),
              DropdownMenuItem(value: 'completed', child: Text('Завершён')),
              DropdownMenuItem(value: 'looking_for_team', child: Text('Ищу команду')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStatus = value);
              }
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
