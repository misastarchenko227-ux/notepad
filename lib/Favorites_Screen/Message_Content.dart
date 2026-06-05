import 'package:flutter/material.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Main_Functions/Photo/PhotoPreview.dart';

import 'package:notepad/Main_Functions/VoiceMessagePlayer.dart';
import 'package:notepad/Main_Functions/video/VideoPreview.dart';

class MessageContent extends StatelessWidget {
  final Message msg;
  final bool isSelectionMode;
  final VoidCallback onToggleSelection; // ← добавь
  const MessageContent({
    super.key,
    required this.msg,
    required this.isSelectionMode,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parts = msg.content.split('|');
    final String path = parts[0];
    final String? comment = parts.length > 1 ? parts[1] : null;
    final TextStyle textStyle = TextStyle(
      fontSize: 16,
      color: colorScheme.onSurface,
    );

    if (path.endsWith('.m4a') || path.endsWith('.wav')) {
      return VoiceMessagePlayer(path: path);
    }

    if (msg.isVideo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VideoPreview(
            msgId: msg.id,
            videoPath: path,
            initialPosition: msg.position,
            isFullScreen: false,
          ),
          if (comment != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(comment, style: textStyle),
            ),
        ],
      );
    }

    if (path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp')) {
      return PhotoPreview(
        msgId: msg.id,
        photoPath: path,
        comment: comment,
        isSelectionMode: isSelectionMode,
        onLongPress: () {},
        // фото не участвует в выделении через MessageContent
        onTapInSelection: () {}, // выделение обрабатывает MessageBubble выше
      );
    }

    return Text(msg.content, style: textStyle);
  }
}
