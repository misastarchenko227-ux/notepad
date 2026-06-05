import 'package:flutter/material.dart';
import 'package:notepad/Input_Panel/Note_Details_Controller.dart';

class InputPanel extends StatelessWidget {
  final NoteDetailsController controller;

  const InputPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              controller.isRecording ? Icons.stop : Icons.mic,
              color: controller.isRecording ? Colors.red : colorScheme.primary,
            ),
            onPressed: controller.toggleRecording,
          ),
          IconButton(
            icon: const Icon(Icons.image, color: Colors.blue),
            onPressed: () => controller.addMedia(context, false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.redAccent),
            onPressed: () => controller.addMedia(context, true),
          ),
          Expanded(
            child: TextField(
              controller: controller.messageController,
              maxLines: null,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Сообщение',
                hintStyle: TextStyle(color: colorScheme.outline),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceVariant.withOpacity(0.4)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: controller.sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}