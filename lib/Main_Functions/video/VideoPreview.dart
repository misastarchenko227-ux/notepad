import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notepad/Main_Functions/Photo/Full_Screen_Image.dart';
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
  final List<String>? allMediaPaths;
  final int? currentIndex;
  final bool isSelectionMode;
  final VoidCallback? onTapInSelection;
  final VoidCallback? onVideoEnded;
  final bool autoPlay;
  final bool manageOrientation; // ← новое: false, если ориентацию контролирует родитель (Full_Screen_Image)

  const VideoPreview({
    Key? key,
    required this.msgId,
    required this.videoPath,
    this.initialPosition = 0,
    this.controller,
    this.isFullScreen = false,
    this.allMediaPaths,
    this.currentIndex,
    this.isSelectionMode = false,
    this.onTapInSelection,
    this.onVideoEnded,
    this.autoPlay = false,
    this.manageOrientation = true, // ← новое: по умолчанию управляет сам (для отдельной кнопки fullscreen)
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
  bool _endedFired = false;

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
          if (mounted) {
            setState(() => _initialized = true);
            if (widget.autoPlay) {
              _controller.play();
            }
          }
        });
    }
    _controller.addListener(_handlePlaybackChange);
    _controller.addListener(_handleVideoEnd);

    // Ориентацию задаём только если сами за неё отвечаем — когда виджет
    // используется внутри Full_Screen_Image, там за это отвечает родитель,
    // и лишний вызов здесь приводил к конфликту при быстром свайпе.
    if (widget.isFullScreen && widget.manageOrientation) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _handleVideoEnd() {
    if (_endedFired) return;
    final value = _controller.value;
    if (!value.isInitialized || value.duration == Duration.zero) return;

    final bool reachedEnd = value.position >= value.duration && !value.isPlaying;
    if (reachedEnd) {
      _endedFired = true;
      widget.onVideoEnded?.call();
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
    if (_initialized && widget.msgId != 0) {
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
    _controller.removeListener(_handleVideoEnd);
    WakelockPlus.disable();
    _savePosition();

    // Останавливаем воспроизведение сразу, не дожидаясь фактического
    // освобождения ресурсов — иначе звук/видео может доиграть на долю
    // секунды дольше, чем виден сам виджет.
    _controller.pause();

    // Раньше здесь стояло "!widget.isFullScreen && widget.controller == null" —
    // из-за этого контроллер, созданный самим виджетом (widget.controller == null),
    // не освобождался, если isFullScreen был true, и видео продолжало играть
    // в фоне после ухода со страницы. Единственное, что реально важно проверять —
    // наш ли это контроллер (widget.controller == null), а не режим отображения.
    if (widget.controller == null) {
      _controller.dispose();
    }

    if (widget.isFullScreen && widget.manageOrientation) {
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
          GestureDetector(
            onTap: () {
              if (widget.isSelectionMode) {
                widget.onTapInSelection?.call();
              } else if (widget.allMediaPaths != null && widget.currentIndex != null) {
                _savePosition();
                _controller.pause();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Full_Screen_Image(
                      paths: widget.allMediaPaths!,
                      initialIndex: widget.currentIndex!,
                    ),
                  ),
                ).then((_) => setState(() {}));
              }
            },
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!widget.isSelectionMode)
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
            child: VideoProgressIndicator(_controller, allowScrubbing: false),
          ),
          if (!widget.isSelectionMode)
            Positioned(
              top: 5, right: 5,
              child: IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white70),
                onPressed: () {
                  _savePosition();
                  _controller.pause();
                  if (widget.allMediaPaths != null && widget.currentIndex != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Full_Screen_Image(
                          paths: widget.allMediaPaths!,
                          initialIndex: widget.currentIndex!,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  } else {
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
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}