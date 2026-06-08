import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

/// Экран создания поста (не проекта!)
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final List<XFile> _images = [];
  XFile? _video;
  final Set<String> _selectedTags = {};
  bool _isPosting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (images.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      final postsDir = Directory('${appDir.path}/posts');
      if (!await postsDir.exists()) await postsDir.create(recursive: true);

      final savedFiles = <XFile>[];
      for (var i = 0;
          i < images.length && _images.length + savedFiles.length < 5;
          i++) {
        final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final savedFile = File('${postsDir.path}/$fileName');
        final bytes = await images[i].readAsBytes();
        await savedFile.writeAsBytes(bytes);
        savedFiles.add(XFile(savedFile.path));
      }
      setState(() => _images.addAll(savedFiles));
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (video != null) {
      setState(() => _video = video);
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _removeVideo() {
    setState(() => _video = null);
  }

  Future<void> _publishPost() async {
    if (_contentController.text.trim().isEmpty && _images.isEmpty && _video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Напишите что-нибудь или добавьте медиа'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isPosting = true);

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final authorId = user.id;
    final postId = 'post_${DateTime.now().millisecondsSinceEpoch}';

    final imagePaths = _images.map((x) => x.path).toList();

    final postAuthor = User(
      id: authorId,
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
      university: user.university,
      faculty: user.faculty,
      course: user.course,
      skills: user.skills,
      createdAt: user.createdAt,
    );

    final post = Post(
      id: postId,
      author: postAuthor,
      content: _contentController.text.trim(),
      images: imagePaths,
      videoUrl: _video?.path,
      tags: _selectedTags.toList(),
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      createdAt: DateTime.now(),
    );

    try {
      await ApiService.instance.createPost(
        content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
        images: _images.map((f) => f.path).toList(),
        tags: _selectedTags.toList(),
        videoPath: _video?.path,
      );
    } catch (e) {
      debugPrint('createPost API error: $e');
    }

    if (!mounted) return;
    setState(() => _isPosting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Пост опубликован!'),
          backgroundColor: AppColors.success),
    );
    Navigator.pop(context);
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
            onPressed: () => Navigator.pop(context)),
        title: const Text('Новый пост',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _publishPost,
            child: _isPosting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary)))
                : const Text('Опубликовать',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Медиа превью
          if (_images.isNotEmpty || _video != null) ...[
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(entry.value.path),
                                width: 100, height: 100, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(entry.key),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_video != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.play_circle_fill,
                                  size: 40, color: Colors.white70),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: _removeVideo,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_images.length < 5 && _video == null)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppColors.divider.withValues(alpha: 0.5))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 28, color: AppColors.textDarkSecondary),
                            const SizedBox(height: 4),
                            Text('Добавить',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textDarkSecondary)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Текст
          TextField(
            controller: _contentController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Что нового?',
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),

          // Кнопки
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Фото'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.divider)),
              ),
              const SizedBox(width: 8),
              Text('${_images.length}/5',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textDarkSecondary)),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _video == null ? _pickVideo : null,
                icon: const Icon(Icons.videocam_outlined, size: 18),
                label: const Text('Видео'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.divider)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Теги
          const Text('Теги',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.defaultSkills.take(15).map((skill) {
              final isSelected = _selectedTags.contains(skill);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected)
                    _selectedTags.remove(skill);
                  else
                    _selectedTags.add(skill);
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(skill,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isSelected ? Colors.white : AppColors.textDark)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
