import 'package:flutter/material.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Favorites_Screen/Message_Content.dart';


class Message_Style extends StatelessWidget {
  final Message msg;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final List<String> mediaPaths; // ← добавь
  final int mediaIndex;
  const Message_Style({
    super.key,
    required this.msg,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onLongPress,
    required this.onTap,
    required this.mediaPaths,    // ← добавь
    required this.mediaIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              border: isSelected ? Border.all(color: colorScheme.primary, width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: MessageContent(
              msg: msg,
              isSelectionMode: isSelectionMode,
              onToggleSelection: onLongPress, // ← передаём тот же что у пузыря
              mediaPaths: mediaPaths,   // ← добавь
              mediaIndex: mediaIndex,   // ← добавь
            ),
          ),
          if (msg.isFavorite)
            const Positioned(
              top: 10,
              right: 20,
              child: Icon(Icons.star, color: Colors.amber, size: 20),
            ),
        ],
      ),
    );
  }
}