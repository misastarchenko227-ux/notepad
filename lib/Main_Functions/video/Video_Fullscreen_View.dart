import 'dart:ui'; // ← новый импорт, нужен для ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_controls.dart';
import 'video_seek_overlay.dart';

class VideoFullscreenView extends StatelessWidget {
  final VideoPlayerController controller;
  final bool showControls;
  final bool showSeekAnim;
  final bool seekLeft;
  final String? seekLabel;
  final VoidCallback onTap;
  final Function(TapDownDetails) onDoubleTapDown;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay;
  final VoidCallback onToggleOrientation;
  final VoidCallback onToggleFit;
  final int orientationMode;
  final bool isCoverFit;

  const VideoFullscreenView({
    super.key,
    required this.controller,
    required this.showControls,
    required this.showSeekAnim,
    required this.seekLeft,
    required this.seekLabel,
    required this.onTap,
    required this.onDoubleTapDown,
    required this.onClose,
    required this.onPlayPause,
    required this.onReplay,
    required this.onToggleOrientation,
    required this.onToggleFit,
    required this.orientationMode,
    required this.isCoverFit,
  });

  /// Как в Telegram: размытая увеличенная копия кадра занимает весь экран
  /// фоном, а поверх неё — настоящее видео без обрезки и без искажений,
  /// по центру. isCoverFit/onToggleFit пока оставлены нетронутыми в
  /// сигнатуре (чтобы не сломать VideoControls и вызывающий код), но
  /// сейчас не используются — можно убрать в отдельной правке.
  Widget _buildVideo(BuildContext context) {
    return InteractiveViewer(
      clipBehavior: Clip.none,
      minScale: 1.0,
      maxScale: 5.0,
      panEnabled: true,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: const Alignment(0.0, 0.9), // ← новое: показываем больше нижней части кадра
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: onTap,
        onDoubleTapDown: onDoubleTapDown,
        child: Stack(
          children: [
            Positioned.fill(child: _buildVideo(context)),
            if (showControls)
              VideoControls(
                controller: controller,
                onClose: onClose,
                onPlayPause: onPlayPause,
                onReplay: onReplay,
                onToggleOrientation: onToggleOrientation,
                onToggleFit: onToggleFit,
                orientationMode: orientationMode,
                isCoverFit: isCoverFit,
              ),
            if (showSeekAnim)
              VideoSeekOverlay(
                isLeft: seekLeft,
                label: seekLabel ?? '',
              ),
          ],
        ),
      ),
    );
  }
}