import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Диалог скачивания файла проекта с прогрессом
class ProjectDownloadDialog extends StatefulWidget {
  final String projectId;
  final String fileName;
  final String fileSize;
  final String? downloadUrl;

  const ProjectDownloadDialog({
    super.key,
    required this.projectId,
    required this.fileName,
    required this.fileSize,
    this.downloadUrl,
  });

  @override
  State<ProjectDownloadDialog> createState() => _ProjectDownloadDialogState();
}

class _ProjectDownloadDialogState extends State<ProjectDownloadDialog> {
  double _progress = 0;
  bool _isComplete = false;
  bool _hasError = false;
  String? _downloadedPath;
  String _statusText = 'Подготовка к скачиванию...';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      // Запрашиваем разрешение на хранение файлов
      PermissionStatus status;
      
      if (Platform.isAndroid) {
        // Для Android 13+ (API 33+) используем новое разрешение
        if (await Permission.storage.isGranted || 
            await Permission.manageExternalStorage.isGranted) {
          status = PermissionStatus.granted;
        } else {
          // Пробуем запросить разрешение
          status = await Permission.manageExternalStorage.request();
          
          // Если не удалось, пробуем старое разрешение
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
        }
        
        if (!status.isGranted) {
          setState(() {
            _hasError = true;
            _statusText = 'Нет разрешения на сохранение файлов';
          });
          
          // Показываем диалог с объяснением
          if (mounted && status.isPermanentlyDenied) {
            _showPermissionSettingsDialog();
          }
          return;
        }
      }

      setState(() {
        _statusText = 'Скачивание...';
      });

      final downloadPath = await ApiService.instance.downloadProjectZipFile(
        projectId: widget.projectId,
        fileName: widget.fileName,
        directUrl: widget.downloadUrl,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _progress = total > 0 ? received / total : 0;
            });
          }
        },
      );

      if (mounted) {
        if (downloadPath != null) {
          setState(() {
            _isComplete = true;
            _downloadedPath = downloadPath;
            _progress = 1.0;
            _statusText = 'Скачивание завершено!';
          });

          // Закрываем диалог через 1.5 секунды
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context, downloadPath);
            }
          });
        } else {
          setState(() {
            _hasError = true;
            _statusText = 'Ошибка при скачивании файла';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusText = 'Ошибка: $e';
        });
      }
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Требуется разрешение',
          style: TextStyle(color: AppColors.textDark),
        ),
        content: const Text(
          'Для скачивания файлов необходимо разрешение на хранение данных. Пожалуйста, включите его в настройках приложения.',
          style: TextStyle(color: AppColors.textDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Настройки'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: _hasError
                    ? const LinearGradient(
                        colors: [AppColors.error, Color(0xFFF97316)],
                      )
                    : _isComplete
                        ? const LinearGradient(
                            colors: [AppColors.success, Color(0xFF10B981)],
                          )
                        : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _hasError
                    ? Icons.error_outline_rounded
                    : _isComplete
                        ? Icons.check_circle_rounded
                        : Icons.download_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Имя файла
            Text(
              widget.fileName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Размер файла
            Text(
              widget.fileSize,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textDarkSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // Прогресс бар
            if (!_hasError) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceDarkLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isComplete ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Процент и статус
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    _statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                _statusText,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Кнопка повторить
              ElevatedButton.icon(
                onPressed: _startDownload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Кнопка отмены (если не завершено)
            if (!_isComplete && !_hasError)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Отмена',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textDarkSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Функция для показа диалога скачивания
Future<String?> showProjectDownloadDialog({
  required BuildContext context,
  required String projectId,
  required String fileName,
  required String fileSize,
  String? downloadUrl,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ProjectDownloadDialog(
      projectId: projectId,
      fileName: fileName,
      fileSize: fileSize,
      downloadUrl: downloadUrl,
    ),
  );
}
