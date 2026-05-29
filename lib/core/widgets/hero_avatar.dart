import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Кастомный аватар с Hero анимацией
class HeroAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool hasStoryGradient;
  final double gradientWidth;
  final VoidCallback? onTap;
  final String heroTag;

  const HeroAvatar({
    super.key,
    required this.heroTag,
    this.imageUrl,
    this.radius = 20,
    this.hasStoryGradient = false,
    this.gradientWidth = 2.5,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocalFile = imageUrl != null &&
        (imageUrl!.startsWith('/') || imageUrl!.startsWith('file://'));
    final imagePath = isLocalFile
        ? (imageUrl!.startsWith('file://')
            ? imageUrl!.replaceFirst('file://', '')
            : imageUrl!)
        : null;

    final Widget avatarContent;

    if (isLocalFile && imagePath != null) {
      avatarContent = ClipOval(
        child: Image.file(
          File(imagePath),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatarContent = ClipOval(
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
      avatarContent = _buildPlaceholder();
    }

    final avatar = Hero(
      tag: heroTag,
      child: avatarContent,
    );

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

    return GestureDetector(onTap: onTap, child: avatar);
  }

  Widget _buildPlaceholder() {
    return Hero(
      tag: '${heroTag}_placeholder',
      child: Container(
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
      ),
    );
  }
}
