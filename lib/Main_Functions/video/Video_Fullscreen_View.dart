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

  Widget _buildVideo(BuildContext context) {
    return InteractiveViewer(
      clipBehavior: Clip.none,
      minScale: 1.0,
      maxScale: 5.0,
      panEnabled: true,
      child: Center(
        child: isCoverFit
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              )
            : AspectRatio(
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