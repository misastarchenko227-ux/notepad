import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoControls extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay;
  final VoidCallback onToggleOrientation;
  final VoidCallback onToggleFit;
  final int orientationMode; // 0: Auto, 1: Landscape Locked, 2: Portrait Locked
  final bool isCoverFit;

  const VideoControls({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onPlayPause,
    required this.onReplay,
    required this.onToggleOrientation,
    required this.onToggleFit,
    required this.orientationMode,
    required this.isCoverFit,
  });

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    IconData orientationIcon;
    switch (orientationMode) {
      case 1:
        orientationIcon = Icons.screen_lock_landscape;
        break;
      case 2:
        orientationIcon = Icons.screen_lock_portrait;
        break;
      default:
        orientationIcon = Icons.screen_rotation;
    }

    return Stack(
      children: [
        Container(color: Colors.black26),
        Align(
          alignment: Alignment.center,
          child: IconButton(
            iconSize: 80,
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white.withOpacity(0.8),
            ),
            onPressed: onPlayPause,
          ),
        ),
        // Кнопка поворота
        Positioned(
          bottom: 90,
          right: 20,
          child: IconButton(
            icon: Icon(orientationIcon, color: Colors.white, size: 30),
            onPressed: onToggleOrientation,
          ),
        ),
        // Кнопка масштаба (растягивание)
        Positioned(
          bottom: 140,
          right: 20,
          child: IconButton(
            icon: Icon(
              isCoverFit ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
              size: 30,
            ),
            onPressed: onToggleFit,
          ),
        ),
        Positioned(
          bottom: 40,
          left: 20,
          child: IconButton(
            icon: const Icon(Icons.replay, color: Colors.white, size: 30),
            onPressed: onReplay,
          ),
        ),
        Positioned(
          bottom: 62,
          left: 20,
          right: 20,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final position = controller.value.position;
              final duration = controller.value.duration;
              return Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: VideoProgressIndicator(controller, allowScrubbing: true),
        ),
      ],
    );
  }
}