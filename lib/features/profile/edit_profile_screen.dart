import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';

/// Экран редактирования профиля
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _universityController;
  late TextEditingController _facultyController;
  late TextEditingController _courseController;

  final Set<String> _selectedSkills = {};
  File? _avatarFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);

    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _universityController = TextEditingController(text: user?.university ?? '');
    _facultyController = TextEditingController(text: user?.faculty ?? '');
    _courseController = TextEditingController(text: user?.course ?? '');

    if (user != null) {
      _selectedSkills.addAll(user.skills);
      // Если аватар — локальный файл, загружаем его
      if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
        final isLocal = user.avatarUrl!.startsWith('/') ||
            user.avatarUrl!.contains('/data/') ||
            user.avatarUrl!.startsWith('file://');
        if (isLocal) {
          final path = user.avatarUrl!.startsWith('file://')
              ? user.avatarUrl!.replaceFirst('file://', '')
              : user.avatarUrl!;
          _avatarFile = File(path);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _universityController.dispose();
    _facultyController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();

      if (!mounted) return;

      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (!mounted) return;
      Navigator.pop(context); // Убираем индикатор

      if (image == null) return;

      debugPrint('Selected image path: ${image.path}');

      // Копируем в постоянную директорию
      final appDir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory('${appDir.path}/avatars');
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }

      // Удаляем старые аватары текущего пользователя
      final user = ref.read(currentUserProvider);
      if (user != null) {
        try {
          final oldAvatarPath = user.avatarUrl;
          if (oldAvatarPath != null && oldAvatarPath.contains('/avatars/')) {
            final oldFile = File(oldAvatarPath);
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          }
        } catch (e) {
          debugPrint('Error deleting old avatar: $e');
        }
      }

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${avatarsDir.path}/$fileName');

      // Читаем байты из исходного файла
      final bytes = await image.readAsBytes();
      debugPrint('Read ${bytes.length} bytes');

      await savedFile.writeAsBytes(bytes);
      debugPrint('Saved to: ${savedFile.path}');
      debugPrint('File exists: ${await savedFile.exists()}');

      setState(() {
        _avatarFile = savedFile;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Аватар загружен ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking avatar: $e');
      if (mounted) {
        // Закрываем индикатор если он есть
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка загрузки аватара: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final avatarPath = _avatarFile?.path;
    debugPrint('=== SAVE PROFILE ===');
    debugPrint('Avatar path: $avatarPath');
    debugPrint('Avatar file exists: ${_avatarFile?.existsSync()}');
    debugPrint('====================');

    try {
      final user = await ApiService.instance.updateProfile({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        'university': _universityController.text.trim().isEmpty
            ? null
            : _universityController.text.trim(),
        'faculty': _facultyController.text.trim().isEmpty
            ? null
            : _facultyController.text.trim(),
        'course': _courseController.text.trim().isEmpty
            ? null
            : _courseController.text.trim(),
        'skills': _selectedSkills.toList(),
        'avatar_url': avatarPath,
      });
      ref.read(currentUserProvider.notifier).updateUser(user);
    } catch (e) {
      debugPrint('updateProfile error: $e');
    }

    if (!mounted) return;

    // Принудительно перезагружаем текущего пользователя
    await ref.read(currentUserProvider.notifier).refresh();

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль сохранён'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Редактировать',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : const Text(
                    'Сохранить',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Аватар
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    _avatarFile != null
                        ? ClipOval(
                            child: Image.file(
                              _avatarFile!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceDark,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 36,
                                    color: AppColors.textDarkSecondary,
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 36,
                              color: AppColors.textDarkSecondary,
                            ),
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Имя
            _buildTextField(
              controller: _nameController,
              label: 'Имя',
              hint: 'Ваше имя',
              icon: Icons.person_outline,
              validator: (v) => v == null || v.isEmpty ? 'Введите имя' : null,
            ),

            const SizedBox(height: 16),

            // Био
            _buildTextField(
              controller: _bioController,
              label: 'О себе',
              hint: 'Расскажите о себе...',
              icon: Icons.edit_outlined,
              maxLines: 3,
              maxLength: 200,
            ),

            const SizedBox(height: 16),

            // Университет
            _buildTextField(
              controller: _universityController,
              label: 'Университет',
              hint: 'Ваш университет',
              icon: Icons.school_outlined,
            ),

            const SizedBox(height: 16),

            // Факультет
            _buildTextField(
              controller: _facultyController,
              label: 'Факультет',
              hint: 'Например: ИУ7',
              icon: Icons.menu_book_outlined,
            ),

            const SizedBox(height: 16),

            // Курс
            _buildTextField(
              controller: _courseController,
              label: 'Курс',
              hint: 'Например: 4',
              icon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // Навыки
            const Text(
              'Навыки',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Выбрано: ${_selectedSkills.length}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDarkSecondary,
              ),
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          skill,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}
