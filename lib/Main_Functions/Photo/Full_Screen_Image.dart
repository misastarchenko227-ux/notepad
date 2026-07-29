import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notepad/Main_Functions/video/VideoPreview.dart';

import '../video/MediaItem.dart'; // ← новый импорт

class Full_Screen_Image extends StatefulWidget {
  final List<MediaItem> items; // ← было List<String> paths
  final int initialIndex;

  const Full_Screen_Image({
    super.key,
    required this.items, // ← было paths
    required this.initialIndex,
  });

  @override
  State<Full_Screen_Image> createState() => _Full_Screen_ImageState();
}

class _Full_Screen_ImageState extends State<Full_Screen_Image> {
  late PageController _pageController;
  late int _currentIndex;
  int? _autoPlayIndex;
  bool? _lastAppliedIsVideo;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _applyOrientationForIndex(_currentIndex);
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

  void _applyOrientationForIndex(int index) {
    final bool isVideo = _isVideo(widget.items[index].path);
    if (_lastAppliedIsVideo == isVideo) return;
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
    if (_currentIndex < widget.items.length - 1) {
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
          '${_currentIndex + 1} / ${widget.items.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
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
          _applyOrientationForIndex(index);
        },
        itemBuilder: (context, index) {
          final item = widget.items[index];

          if (_isVideo(item.path)) {
            return VideoPreview(
              msgId: item.msgId, // ← было 0
              videoPath: item.path,
              initialPosition: item.initialPosition, // ← новое: продолжаем с сохранённого места
              isFullScreen: true,
              onVideoEnded: _goToNextIfAvailable,
              autoPlay: index == _autoPlayIndex,
              manageOrientation: false,
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
    );
  }
}