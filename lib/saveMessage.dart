import 'dart:io';
import 'package:flutter/material.dart';
import 'main.dart';
import 'Data_Base/database.dart';
import 'message_item.dart';


class FullScreenImage extends StatelessWidget {
  final String path;
  const FullScreenImage({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: InteractiveViewer( // Позволяет зумить пальцами
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}