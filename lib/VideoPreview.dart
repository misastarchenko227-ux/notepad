import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notepad/main.dart';
import 'package:video_player/video_player.dart';

// === Видео ===
class VideoPreview extends StatefulWidget {
  final int msgId;
  final String videoPath;
  final int initialPosition;
  final VideoPlayerController? controller;
  final bool isFullScreen;

  const VideoPreview({
    Key? key,
    required this.msgId,
    required this.videoPath,
    this.initialPosition = 0,
    this.controller,
    this.isFullScreen = false,
  }) : super(key: key);

  @override
  _VideoPreviewState createState() => _VideoPreviewState();
}

// === Твой существующий класс состояния ===
class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _initialized = true;
    } else {
      _controller = VideoPlayerController.file(File(widget.videoPath))
        ..initialize().then((_) {
          if (widget.initialPosition > 0) {
            _controller.seekTo(Duration(seconds: widget.initialPosition));
          }
          setState(() => _initialized = true);
        });
    }

    if (widget.isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _savePosition() {
    if (_initialized) {
      database.updateVideoPosition(widget.msgId, _controller.value.position.inSeconds);
    }
  }

  @override
  void dispose() {
    _savePosition();
    if (!widget.isFullScreen && widget.controller == null) {
      _controller.dispose();
    }
    if (widget.isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator());

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              ),
              if (_showControls) ...[
                Container(color: Colors.black26),
                Align(alignment: Alignment.center, child: _buildPlayButton()),
                Positioned(
                  top: 20,
                  left: 20,
                  child: SafeArea(
                      child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 35),
                          onPressed: () => Navigator.pop(context)
                      )
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: IconButton(
                      icon: const Icon(Icons.replay, color: Colors.white, size: 30),
                      onPressed: () => _controller.seekTo(Duration.zero)
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: VideoProgressIndicator(_controller, allowScrubbing: true),
                ),
              ]
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          _buildPlayButton(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(_controller, allowScrubbing: true),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white70),
              onPressed: () {
                _savePosition();
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => VideoPreview(
                        msgId: widget.msgId,
                        videoPath: widget.videoPath,
                        controller: _controller,
                        isFullScreen: true
                    )
                )).then((_) => setState(() {}));
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return IconButton(
      iconSize: widget.isFullScreen ? 80 : 50,
      icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white.withOpacity(0.8)),
      onPressed: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
          _savePosition();
        });
      },
    );
  }
}