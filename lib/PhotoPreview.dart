import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notepad/saveMessage.dart';
// Фото
class PhotoPreview extends StatelessWidget {
  final int msgId;
  final String photoPath;
  final String? comment;
  final bool isSelectionMode;
  final VoidCallback onLongPress;
  final VoidCallback onTapInSelection;

  const PhotoPreview({
    Key? key,
    required this.msgId,
    required this.photoPath,
    this.comment,
    required this.isSelectionMode,
    required this.onLongPress,
    required this.onTapInSelection,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(fontSize: 16, color: colorScheme.onSurface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: onLongPress,
          onTap: () {
            if (isSelectionMode) {
              onTapInSelection();
            } else {
              FullScreenImage(path: photoPath);
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
            child: Text(comment!, style: textStyle),
          ),
      ],
    );
  }
}