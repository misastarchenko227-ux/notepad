import 'package:flutter/material.dart';
import 'package:notepad/Input_Panel/Note_Details_Controller.dart';

class InputPanel extends StatelessWidget {
  final NoteDetailsController controller;

  const InputPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // SafeArea учитывает системные вырезы (notch) и жестовую навигацию
    // снизу экрана — без него панель ввода может залезть под системные
    // элементы на iPhone без кнопки Home и на многих Android-устройствах.
    return SafeArea(
      top: false, // сверху SafeArea не нужен — панель ввода внизу экрана
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end, // кнопки прижаты к низу,
          // когда TextField растягивается на несколько строк
          children: [
            IconButton(
              icon: Icon(
                controller.isRecording ? Icons.stop : Icons.mic,
                color: controller.isRecording ? Colors.red : colorScheme.primary,
              ),
              onPressed: () => controller.toggleRecording(context), // ← передаём context для диалога подписи
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
                minLines: 1,
                maxLines: 5, // было: null — теперь поле растёт максимум
                // до 5 строк, дальше появляется собственный внутренний скролл
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
                onPressed: () => controller.sendMessage(context), // ← передаём context для диалога подписи
              ),
            ),
          ],
        ),
      ),
    );
  }
}