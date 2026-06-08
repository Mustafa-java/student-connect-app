import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
        errorWidget: (context, url, error) => errorWidget ?? _defaultErrorWidget(),
        memCacheWidth: width?.isFinite == true ? width!.toInt() : null,
        memCacheHeight: height?.isFinite == true ? height!.toInt() : null,
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
    final iconSize = (width?.isFinite == true ? width! : 40.0) * 0.5;
    return Container(
      width: width,
      height: height,
      color: AppColors.skeleton,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: iconSize,
          color: AppColors.textDarkSecondary,
        ),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    final iconSize = (width?.isFinite == true ? width! : 40.0) * 0.5;
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceDark,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: iconSize,
          color: AppColors.textDarkSecondary,
        ),
      ),
    );
  }
}
