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
    final screenSize = MediaQuery.of(context).size;
    final videoRatio = controller.value.aspectRatio;
    final screenRatio = screenSize.width / screenSize.height;

    double baseScale = videoRatio < screenRatio
        ? screenSize.width / (screenSize.height * videoRatio)
        : screenSize.height * videoRatio / screenSize.width;

    return Transform.scale(
      scale: baseScale,
      child: Center(
        child: AspectRatio(
          aspectRatio: videoRatio,
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