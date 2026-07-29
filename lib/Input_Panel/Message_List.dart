import 'package:flutter/material.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Input_Panel/Note_Details_Controller.dart';
import 'package:notepad/Main_Screen/main.dart';
import 'package:notepad/Message_Style/Message_Bubble.dart';
import 'package:notepad/Message_Style/Message_Group_Bubble.dart'; // ← новый импорт

class MessageList extends StatelessWidget {
  final NoteDetailsController controller;
  final int noteId;

  const MessageList({super.key, required this.controller, required this.noteId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<Message>>(
      stream: database.watchMessagesForNote(noteId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        controller.currentMessages = snapshot.data!;

        if (controller.currentMessages.isEmpty) {
          return Center(
            child: Text("Сообщений пока нет", style: TextStyle(color: colorScheme.outline)),
          );
        }

        // Собираем все медиафайлы (фото + видео) в один список
        final List<String> mediaPaths = controller.currentMessages
            .where((m) {
          final path = m.content.split('|')[0];
          return m.isVideo ||
              path.endsWith('.jpg') || path.endsWith('.jpeg') ||
              path.endsWith('.png') || path.endsWith('.webp');
        })
            .map((m) => m.content.split('|')[0])
            .toList();

        // Сообщения с одинаковым groupId, идущие подряд, объединяем в один
        // элемент-пакет — они всегда идут подряд, потому что addMedia
        // сохраняет их последовательным циклом с await.
        final List<Object> displayItems = []; // Message | List<Message>
        int i = 0;
        while (i < controller.currentMessages.length) {
          final msg = controller.currentMessages[i];
          if (msg.groupId != null) {
            final group = <Message>[msg];
            int j = i + 1;
            while (j < controller.currentMessages.length &&
                controller.currentMessages[j].groupId == msg.groupId) {
              group.add(controller.currentMessages[j]);
              j++;
            }
            displayItems.add(group);
            i = j;
          } else {
            displayItems.add(msg);
            i++;
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];

            // Пакет из нескольких файлов — рисуем гридом
            if (item is List<Message>) {
              return MessageGroupBubble(
                group: item,
                isSelectionMode: controller.isSelectionMode,
                selectedIds: controller.selectedMessageIds,
                allMediaPaths: mediaPaths,
                onToggleSelection: (id) => controller.toggleSelection(id),
              );
            }

            // Одиночное сообщение — как раньше
            final msg = item as Message;
            final path = msg.content.split('|')[0];
            final isMedia = msg.isVideo ||
                path.endsWith('.jpg') || path.endsWith('.jpeg') ||
                path.endsWith('.png') || path.endsWith('.webp');
            final mediaIndex = isMedia ? mediaPaths.indexOf(path) : 0;

            return Message_Style(
              msg: msg,
              isSelected: controller.selectedMessageIds.contains(msg.id),
              isSelectionMode: controller.isSelectionMode,
              mediaPaths: mediaPaths,     // ← передаём список
              mediaIndex: mediaIndex,     // ← передаём индекс
              onLongPress: () => controller.toggleSelection(msg.id),
              onTap: () => controller.isSelectionMode
                  ? controller.toggleSelection(msg.id)
                  : null,
            );
          },
        );
      },
    );
  }
}