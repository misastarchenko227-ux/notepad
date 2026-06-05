import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoControls extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay;

  const VideoControls({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onPlayPause,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
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
        Positioned(
          top: 20,
          left: 20,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 35),
              onPressed: onClose,
            ),
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
          bottom: 20,
          left: 20,
          right: 20,
          child: VideoProgressIndicator(controller, allowScrubbing: true),
        ),
      ],
    );
  }
}