import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isVideo(String path) =>
      path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');

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
        physics: const ClampingScrollPhysics(),
        itemCount: widget.paths.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final path = widget.paths[index];

          if (_isVideo(path)) {
            return Center(
              child: VideoPreview(
                msgId: 0,
                videoPath: path,
                isFullScreen: false,
                // Не передаем allMediaPaths здесь, чтобы не было зацикливания галереи
              ),
            );
          }

          return InteractiveViewer(
            panEnabled: false,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.file(File(path)),
            ),
          );
        },
      ),
    );
  }
}
