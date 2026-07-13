import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Main_Functions/Photo/PhotoPreview.dart';
import 'package:notepad/Main_Functions/VoiceMessagePlayer.dart';
import 'package:notepad/Main_Functions/video/VideoPreview.dart';

class MessageContent extends StatelessWidget {
  final Message msg;
  final bool isSelectionMode;        // для заметок
  final VoidCallback? onToggleSelection; // для заметок
  final List<String>? mediaPaths;    // для заметок
  final int? mediaIndex;             // для заметок
  final VoidCallback? onImageTap;    // для избранного

  const MessageContent({
    super.key,
    required this.msg,
    this.isSelectionMode = false,    // по умолчанию false
    this.onToggleSelection,
    this.mediaPaths,
    this.mediaIndex,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parts = msg.content.split('|');
    final String path = parts[0];
    final String? comment = parts.length > 1 ? parts[1] : null;
    final TextStyle textStyle = TextStyle(fontSize: 16, color: colorScheme.onSurface);

    // Голосовое
    // Голосовое — вторая часть после '|' это волна (амплитуды через запятую),
    // а не подпись, как у фото/видео. Парсим отдельно от comment.
    // Голосовое: content = path|waveform|caption (caption опционален)
    if (path.endsWith('.m4a') || path.endsWith('.wav')) {
      final String? waveformRaw = parts.length > 1 ? parts[1] : null;
      final String? voiceCaption = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;

      final List<double> waveform = waveformRaw != null && waveformRaw.isNotEmpty
          ? waveformRaw.split(',').map(double.parse).toList()
          : const [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VoiceMessagePlayer(path: path, waveform: waveform),
          if (voiceCaption != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(voiceCaption, style: textStyle),
            ),
        ],
      );
    }

    // Видео
    if (msg.isVideo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VideoPreview(
            msgId: msg.id,
            videoPath: path,
            initialPosition: msg.position,
            isFullScreen: false,
            allMediaPaths: mediaPaths,
            currentIndex: mediaIndex,
            isSelectionMode: isSelectionMode,
            onTapInSelection: onToggleSelection,
          ),
          if (comment != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(comment, style: textStyle),
            ),
        ],
      );
    }

    // Фото
    final p = path.toLowerCase();
    if (p.endsWith('.jpg') || p.endsWith('.jpeg') ||
        p.endsWith('.png') || p.endsWith('.webp')) {

      // Если есть mediaPaths — мы в заметке, используем PhotoPreview
      if (mediaPaths != null && mediaIndex != null) {
        return PhotoPreview(
          msgId: msg.id,
          photoPath: path,
          comment: comment,
          isSelectionMode: isSelectionMode,
          onLongPress: () {},
          onTapInSelection: onToggleSelection ?? () {},
          allMediaPaths: mediaPaths!,
          currentIndex: mediaIndex!,
        );
      }

      // Иначе мы в избранном — простой GestureDetector
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onImageTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(path),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  width: double.infinity,
                  color: colorScheme.surfaceVariant,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
          if (comment != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(comment, style: textStyle),
            ),
        ],
      );
    }

    // Текст
    return Text(msg.content, style: textStyle);
  }
}