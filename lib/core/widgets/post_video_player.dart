import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_colors.dart';

/// Виджет для проигрывания видео в постах
class PostVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final double? height;
  final bool autoPlay;

  const PostVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.height,
    this.autoPlay = false,
  });

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showPlayer = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) _initController(autoPlay: true);
  }

  void _initController({bool autoPlay = false}) {
    try {
      final uri = Uri.tryParse(widget.videoUrl);
      if (uri == null || !uri.hasScheme || widget.videoUrl.isEmpty) {
        debugPrint('VideoPlayer: invalid URL: ${widget.videoUrl}');
        if (mounted) setState(() => _hasError = true);
        return;
      }
      _controller = VideoPlayerController.networkUrl(uri)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
            _controller!.setLooping(true);
            _controller!.setVolume(0);
            if (autoPlay) _controller!.play();
          }
        }).catchError((error) {
          debugPrint('VideoPlayer init error: $error');
          if (mounted) setState(() => _hasError = true);
        });

      // Таймаут 15 секунд — если видео не загрузилось, показываем ошибку
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && !_isInitialized && !_hasError) {
          setState(() => _hasError = true);
          _controller?.dispose();
          _controller = null;
        }
      });
    } catch (e) {
      debugPrint('VideoPlayer error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _play() {
    if (!mounted) return;
    setState(() => _showPlayer = true);
    if (_controller == null) _initController(autoPlay: true);
  }

  void _togglePlay() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height ?? 350;

    if (_hasError) {
      return Container(
        height: height,
        color: Colors.black26,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_rounded, size: 40, color: Colors.white38),
              const SizedBox(height: 8),
              Text(
                'Видео недоступно',
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    if (!_showPlayer) {
      // Показываем превью (thumbnail) с кнопкой play
      return GestureDetector(
        onTap: _play,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.thumbnailUrl ?? widget.videoUrl,
                height: height,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: height,
                  color: Colors.black26,
                  child: const Icon(Icons.play_circle_outline,
                      size: 48, color: Colors.white38),
                ),
              ),
            ),
            Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black12,
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    size: 56, color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: height,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final videoSize = _controller!.value.size;
    final aspectRatio = videoSize.width > 0 && videoSize.height > 0
        ? videoSize.aspectRatio
        : 16 / 9;

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          if (!_controller!.value.isPlaying)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              colors: VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
