import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Main_Functions/Photo/Full_Screen_Image.dart';

import 'dart:typed_data';

import '../Main_Functions/LinkReader.dart';
import '../Main_Functions/video/MediaItem.dart';

class MessageGroupBubble extends StatelessWidget {
  final List<Message> group;
  final bool isSelectionMode;
  final Set<int> selectedIds;
  final List<MediaItem> allMediaItems; // ← было List<String> allMediaPaths
  final void Function(int messageId) onToggleSelection;

  const MessageGroupBubble({
    super.key,
    required this.group,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.allMediaItems, // ← было allMediaPaths
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = TextStyle(fontSize: 16, color: colorScheme.onSurface);
    final linkStyle = textStyle.copyWith(color: Colors.blue, decoration: TextDecoration.underline);

    final lastParts = group.last.content.split('|');
    final String? caption = lastParts.length > 1 ? lastParts[1] : null;

    final bool anyFavorite = group.any((m) => m.isFavorite);
    final int crossAxisCount = group.length > 4 ? 3 : 2;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final msg = group[index];
                  final path = msg.content.split('|')[0];
                  final isSelected = selectedIds.contains(msg.id);
                  final globalIndex = allMediaItems.indexWhere((mi) => mi.msgId == msg.id);

                  return GestureDetector(
                    onLongPress: () => onToggleSelection(msg.id),
                    onTap: () {
                      if (isSelectionMode) {
                        onToggleSelection(msg.id);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Full_Screen_Image(
                            items: allMediaItems, // ← было paths
                            initialIndex: globalIndex < 0 ? 0 : globalIndex,
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: msg.isVideo
                              ? _VideoThumbnail(path: path)
                              : Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: colorScheme.surfaceVariant,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            color: Colors.black45,
                            child: const Icon(Icons.check_circle, color: Colors.white),
                          ),
                      ],
                    ),
                  );
                },
              ),
              if (caption != null && caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LinkifiedText(text: caption, textStyle: textStyle, linkStyle: linkStyle),
                ),
            ],
          ),
        ),
        if (anyFavorite)
          const Positioned(
            top: 10,
            right: 20,
            child: Icon(Icons.star, color: Colors.amber, size: 20),
          ),
      ],
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String path;

  const _VideoThumbnail({required this.path});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  Uint8List? _thumbnailBytes;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final bytes = await VideoThumbnail.thumbnailData(
      video: widget.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 200,
      quality: 60,
    );
    if (mounted) {
      setState(() => _thumbnailBytes = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnailBytes == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(_thumbnailBytes!, fit: BoxFit.cover),
        const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 32),
        ),
      ],
    );
  }
}