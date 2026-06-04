import 'package:flutter/material.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Message_Bubble.dart';
import 'package:notepad/main.dart';
import 'Note_Details_Controller.dart';
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

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: controller.currentMessages.length,
          itemBuilder: (context, index) {
            final msg = controller.currentMessages[index];
            return MessageBubble(
              msg: msg,
              isSelected: controller.selectedMessageIds.contains(msg.id),
              isSelectionMode: controller.isSelectionMode,
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