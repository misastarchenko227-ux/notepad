import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notepad/Main_Functions/Photo/Full_Screen_Image.dart';

import '../LinkReader.dart';
import '../video/MediaItem.dart';


class PhotoPreview extends StatelessWidget {
  final int msgId;
  final String photoPath;
  final String? comment;
  final bool isSelectionMode;
  final VoidCallback onLongPress;
  final VoidCallback onTapInSelection;
  final List<MediaItem> allMediaItems; // ← было List<String> allMediaPaths
  final int currentIndex;

  const PhotoPreview({
    Key? key,
    required this.msgId,
    required this.photoPath,
    this.comment,
    required this.isSelectionMode,
    required this.onLongPress,
    required this.onTapInSelection,
    required this.allMediaItems, // ← было allMediaPaths
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(fontSize: 16, color: colorScheme.onSurface);
    final linkStyle = textStyle.copyWith(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (isSelectionMode) {
              onTapInSelection();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Full_Screen_Image(
                    items: allMediaItems, // ← было paths
                    initialIndex: currentIndex,
                  ),
                ),
              );
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(photoPath),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (comment != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinkifiedText(text: comment!, textStyle: textStyle, linkStyle: linkStyle),
          ),
      ],
    );
  }
}