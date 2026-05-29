import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Кастомный аватар с поддержкой локальных файлов и сетевых URL
class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool hasStoryGradient;
  final double gradientWidth;
  final VoidCallback? onTap;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.hasStoryGradient = false,
    this.gradientWidth = 2.5,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocalFile = imageUrl != null &&
        imageUrl!.isNotEmpty &&
        (imageUrl!.startsWith('/') ||
            imageUrl!.startsWith('file://') ||
            imageUrl!.contains('/data/') ||
            imageUrl!.contains('content://'));
    final imagePath = isLocalFile
        ? (imageUrl!.startsWith('file://')
            ? imageUrl!.replaceFirst('file://', '')
            : imageUrl!)
        : null;

    final Widget avatar;

    if (isLocalFile && imagePath != null) {
      final file = File(imagePath);
      avatar = FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return ClipOval(
              child: Image.file(
                file,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              ),
            );
          }
          return _buildPlaceholder();
        },
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      );
    } else {
      avatar = _buildPlaceholder();
    }

    if (hasStoryGradient) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(gradientWidth),
          decoration: BoxDecoration(
            gradient: AppColors.storyGradient,
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: EdgeInsets.all(gradientWidth),
            decoration: const BoxDecoration(
              color: AppColors.backgroundDark,
              shape: BoxShape.circle,
            ),
            child: avatar,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: avatar,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkLight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: radius,
        color: AppColors.textDarkSecondary,
      ),
    );
  }
}

/// Аватар для чата с индикатором онлайн
class AvatarWithOnlineIndicator extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool isOnline;

  const AvatarWithOnlineIndicator({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomAvatar(
          imageUrl: imageUrl,
          radius: radius,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.backgroundDark,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
