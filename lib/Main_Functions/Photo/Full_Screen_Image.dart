import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notepad/Main_Functions/video/VideoPreview.dart';

class Full_Screen_Image extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const Full_Screen_Image({
    super.key,
    required this.paths,
    required this.initialIndex,
  });

  @override
  State<Full_Screen_Image> createState() => _Full_Screen_ImageState();
}

class _Full_Screen_ImageState extends State<Full_Screen_Image> {
  late PageController _pageController;
  late int _currentIndex;
  int? _autoPlayIndex;
  bool? _lastAppliedIsVideo; // ← новое: чтобы не дёргать ориентацию повторно без надобности

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _applyOrientationForIndex(_currentIndex); // ← новое: сразу задаём ориентацию под стартовую страницу
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Возвращаем portrait при выходе из галереи целиком — какая бы страница
    // ни была открыта в момент закрытия.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  bool _isVideo(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') || p.endsWith('.mov') || p.endsWith('.avi') || p.endsWith('.mkv');
  }

  /// Единая точка управления ориентацией экрана — раньше каждая страница
  /// VideoPreview сама её выставляла и сбрасывала, из-за чего при быстром
  /// свайпе между несколькими видео происходили конфликтующие вызовы
  /// SystemChrome почти одновременно, и экран "прыгал" между portrait/landscape.
  /// Теперь ориентацию меняет только этот метод, и только когда тип
  /// страницы (видео/фото) реально изменился.
  void _applyOrientationForIndex(int index) {
    final bool isVideo = _isVideo(widget.paths[index]);
    if (_lastAppliedIsVideo == isVideo) return; // тип не поменялся — ничего не трогаем
    _lastAppliedIsVideo = isVideo;

    if (isVideo) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _goToNextIfAvailable() {
    if (_currentIndex < widget.paths.length - 1) {
      setState(() => _autoPlayIndex = _currentIndex + 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.paths.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.paths.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            if (index != _autoPlayIndex) {
              _autoPlayIndex = null;
            }
          });
          _applyOrientationForIndex(index); // ← новое: меняем ориентацию тут, а не в самом VideoPreview
        },
        itemBuilder: (context, index) {
          final path = widget.paths[index];

          if (_isVideo(path)) {
            return VideoPreview(
              msgId: 0,
              videoPath: path,
              isFullScreen: true,
              onVideoEnded: _goToNextIfAvailable,
              autoPlay: index == _autoPlayIndex,
              manageOrientation: false, // ← новое: ориентацию контролирует Full_Screen_Image, не сам виджет
            );
          }

          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            child: Center(
              child: Image.file(
                File(path),
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
    );
  }
}