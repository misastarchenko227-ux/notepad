import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notepad/Main_Functions/video/VideoPreview.dart';

import '../video/MediaItem.dart';

class Full_Screen_Image extends StatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;

  const Full_Screen_Image({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<Full_Screen_Image> createState() => _Full_Screen_ImageState();
}

class _Full_Screen_ImageState extends State<Full_Screen_Image> {
  late PageController _pageController;
  late int _currentIndex;
  int? _autoPlayIndex;

  // Состояние теперь хранится здесь и не сбрасывается при свайпах
  int _orientationMode = 0; // 0: Auto, 1: Landscape, 2: Portrait
  bool _isCoverFit = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _applyCurrentOrientation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  bool _isVideo(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') || p.endsWith('.mov') || p.endsWith('.avi') || p.endsWith('.mkv');
  }

  void _applyCurrentOrientation() {
    if (_orientationMode == 1) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else if (_orientationMode == 2) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      // Режим "Авто"
      final bool isVideo = _isVideo(widget.items[_currentIndex].path);
      if (isVideo) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    }
  }

  void _toggleOrientation() {
    setState(() {
      _orientationMode = (_orientationMode + 1) % 3;
      _applyCurrentOrientation();
    });
  }

  void _toggleFit() {
    setState(() {
      _isCoverFit = !_isCoverFit;
    });
  }

  void _goToNextIfAvailable() {
    if (_currentIndex < widget.items.length - 1) {
      setState(() => _autoPlayIndex = _currentIndex + 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final bool currentIsVideo = _isVideo(widget.items[_currentIndex].path);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true, // ← новое: контент уходит под AppBar
      appBar: currentIsVideo
          ? null // ← на видео-страницах AppBar убираем совсем
          : AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.items.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                if (index != _autoPlayIndex) {
                  _autoPlayIndex = null;
                }
              });
              _applyCurrentOrientation();
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];

              if (_isVideo(item.path)) {
                return VideoPreview(
                  msgId: item.msgId,
                  videoPath: item.path,
                  initialPosition: item.initialPosition,
                  isFullScreen: true,
                  onVideoEnded: _goToNextIfAvailable,
                  autoPlay: index == _autoPlayIndex,
                  manageOrientation: false,
                  externalOrientationMode: _orientationMode,
                  externalIsCoverFit: _isCoverFit,
                  onToggleOrientation: _toggleOrientation,
                  onToggleFit: _toggleFit,
                );
              }

              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: Image.file(
                    File(item.path),
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 50,
                    ),
                  ),
                ),
              );
            },
          ),
          // Кнопка "назад" поверх видео — AppBar на видео-страницах убран,
          // но выйти с экрана всё равно нужно.
          if (currentIsVideo)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}