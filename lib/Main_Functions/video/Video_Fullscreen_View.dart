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
  });

  Widget _buildVideo(BuildContext context) {
    return InteractiveViewer(
      clipBehavior: Clip.none,
      minScale: 1.0,      // исходный размер
      maxScale: 5.0,      // максимальный зум
      panEnabled: true,  // ← запрещаем перемещение, только зум
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
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