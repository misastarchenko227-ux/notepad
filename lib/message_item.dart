import 'dart:io';
import 'package:flutter/material.dart';
import 'database.dart';
// Импортируй свои плееры (убедись, что они доступны)
import 'details_page.dart';

// message_item.dart (или там, где лежит этот виджет)
class MessageContentWidget extends StatelessWidget {
  final Message msg;
  final VoidCallback? onImageTap; // Изменили тип для удобства

  const MessageContentWidget({
    super.key,
    required this.msg,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parts = msg.content.split('|');
    final String path = parts[0];
    final String? comment = parts.length > 1 ? parts[1] : null;
    bool isFilePath = path.startsWith('/');

    TextStyle textStyle = TextStyle(fontSize: 16, color: colorScheme.onSurface);

    if (path.endsWith('.m4a') || path.endsWith('.wav')) {
      return VoiceMessagePlayer(path: path);
    }

    if (msg.isVideo) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VideoPreview(msgId: msg.id, videoPath: path, initialPosition: msg.position, isFullScreen: false),
        if (comment != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(comment, style: textStyle)),
      ]);
    }

    else if (isFilePath) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: onImageTap, // Вызываем переданную функцию
          child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(path), height: 200, width: double.infinity, fit: BoxFit.cover)
          ),
        ),
        if (comment != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(comment, style: textStyle)),
      ]);
    }

    return Text(msg.content, style: textStyle);
  }
}