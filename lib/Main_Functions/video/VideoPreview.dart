import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notepad/Main_Functions/video/Video_Fullscreen_View.dart';
import 'package:notepad/Main_Screen/main.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:video_player/video_player.dart';

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

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _initialized = false;
  String? _seekLabel;
  bool _showSeekAnim = false;
  bool _seekLeft = false;

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
    _controller.addListener(_handlePlaybackChange);
    if (widget.isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _showSeekOverlay(bool isLeft) {
    setState(() {
      _seekLeft = isLeft;
      _seekLabel = isLeft ? '-5с' : '+5с';
      _showSeekAnim = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showSeekAnim = false);
    });
  }

  void _handlePlaybackChange() {
    if (_controller.value.isPlaying) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _savePosition() {
    if (_initialized) {
      database.updateVideoPosition(widget.msgId, _controller.value.position.inSeconds);
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;
    if (tapX < screenWidth / 2) {
      final newPos = _controller.value.position - const Duration(seconds: 5);
      _controller.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
      _showSeekOverlay(true);
    } else {
      _controller.seekTo(_controller.value.position + const Duration(seconds: 5));
      _showSeekOverlay(false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handlePlaybackChange);
    WakelockPlus.disable();
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
      return VideoFullscreenView(
        controller: _controller,
        showControls: _showControls,
        showSeekAnim: _showSeekAnim,
        seekLeft: _seekLeft,
        seekLabel: _seekLabel,
        onTap: () => setState(() => _showControls = !_showControls),
        onDoubleTapDown: _handleDoubleTap,
        onClose: () => Navigator.pop(context),
        onPlayPause: () => setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
          _savePosition();
        }),
        onReplay: () => _controller.seekTo(Duration.zero),
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
          IconButton(
            iconSize: 50,
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white.withOpacity(0.8),
            ),
            onPressed: () => setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
              _savePosition();
            }),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: VideoProgressIndicator(_controller, allowScrubbing: true),
          ),
          Positioned(
            top: 5, right: 5,
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white70),
              onPressed: () {
                _savePosition();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPreview(
                      msgId: widget.msgId,
                      videoPath: widget.videoPath,
                      controller: _controller,
                      isFullScreen: true,
                    ),
                  ),
                ).then((_) => setState(() {}));
              },
            ),
          ),
        ],
      ),
    );
  }
}