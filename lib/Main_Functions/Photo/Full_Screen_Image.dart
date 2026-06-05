import 'dart:io';
import 'package:flutter/material.dart';



class Full_Screen_Image extends StatelessWidget {
  final String path;
  const Full_Screen_Image({super.key, required this.path});

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