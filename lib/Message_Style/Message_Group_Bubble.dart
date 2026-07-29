import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Main_Functions/Photo/Full_Screen_Image.dart';

import '../Main_Functions/LinkReader.dart';

/// Пузырь для пакета из нескольких фото/видео, выбранных за один раз —
/// вместо N отдельных пузырей рисует один грид (как альбом в Telegram).
class MessageGroupBubble extends StatelessWidget {
  final List<Message> group;
  final bool isSelectionMode;
  final Set<int> selectedIds;
  final List<String> allMediaPaths; // общий список для свайпа в полноэкранном режиме
  final void Function(int messageId) onToggleSelection;

  const MessageGroupBubble({
    super.key,
    required this.group,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.allMediaPaths,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = TextStyle(fontSize: 16, color: colorScheme.onSurface);
    final linkStyle = textStyle.copyWith(color: Colors.blue, decoration: TextDecoration.underline);

    // Подпись привязана к последнему файлу пакета — так же, как сохраняет addMedia
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
                  final globalIndex = allMediaPaths.indexOf(path);

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
                            paths: allMediaPaths,
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
                              ? Container(
                            color: Colors.black87,
                            child: const Icon(Icons.play_circle_outline,
                                color: Colors.white, size: 32),
                          )
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