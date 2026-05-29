import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Универсальный виджет для отображения изображений
/// Автоматически определяет: локальный файл или сетевой URL
class SmartImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  bool get _isLocalFile {
    return imageUrl.startsWith('/') ||
        imageUrl.startsWith('file://') ||
        imageUrl.contains('/data/') ||
        imageUrl.contains('content://');
  }

  String get _cleanPath {
    if (imageUrl.startsWith('file://')) {
      return imageUrl.replaceFirst('file://', '');
    }
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget;

    if (_isLocalFile) {
      final file = File(_cleanPath);
      imageWidget = FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return errorWidget ?? _defaultErrorWidget();
              },
            );
          }
          return placeholder ?? _defaultPlaceholder();
        },
      );
    } else {
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _defaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _defaultErrorWidget();
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.skeleton,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: (width ?? 40) * 0.5,
          color: AppColors.textDarkSecondary,
        ),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceDark,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: (width ?? 40) * 0.5,
          color: AppColors.textDarkSecondary,
        ),
      ),
    );
  }
}
