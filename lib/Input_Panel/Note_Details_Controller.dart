import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Main_Screen/main.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


class NoteDetailsController {
  final int noteId;
  final VoidCallback onUpdate;

  final TextEditingController messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  StreamSubscription<Amplitude>? _ampSub;
  List<double> currentAmplitudes = [];

  Set<int> selectedMessageIds = {};
  bool isSelectionMode = false;
  bool isRecording = false;
  List<Message> currentMessages = [];

  NoteDetailsController({required this.noteId, required this.onUpdate});

  bool get allSelectedAreFavorite =>
      selectedMessageIds.every((id) => currentMessages.firstWhere((m) => m.id == id).isFavorite);

  void toggleSelection(int id) {
    if (selectedMessageIds.contains(id)) {
      selectedMessageIds.remove(id);
      if (selectedMessageIds.isEmpty) isSelectionMode = false;
    } else {
      selectedMessageIds.add(id);
      isSelectionMode = true;
    }
    onUpdate();
  }

  void clearSelection() {
    selectedMessageIds.clear();
    isSelectionMode = false;
    onUpdate();
  }

  Future<void> toggleSelectedFavorites() async {
    for (var id in selectedMessageIds) {
      final msg = currentMessages.firstWhere((m) => m.id == id);
      await database.toggleFavorite(msg);
    }
    clearSelection();
  }

  Future<void> deleteSelectedMessages() async {
    await database.deleteMessagesByIds(selectedMessageIds);
    clearSelection();
  }

  Future<void> changeMessage(BuildContext context, Message msg) async {
    final parts = msg.content.split('|');
    final String currentText = msg.isVideo && parts.length > 1 ? parts[1] : parts[0];
    final TextEditingController editController = TextEditingController(text: currentText);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: 'Новый текст...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              String newContent = msg.isVideo
                  ? "${parts[0]}|${editController.text}"
                  : editController.text;
              if (newContent.isNotEmpty) {
                await database.updateMessageContent(msg.id, newContent);
                Navigator.pop(context);
                clearSelection();
              }
            },
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  /// Самолётик: идёт запись — останавливаем и предлагаем подписать голос,
  /// нет записи — шлём текст.
  Future<void> sendMessage(BuildContext context) async {
    if (isRecording) {
      await _stopAndSendVoice(context);
      return;
    }
    if (messageController.text.trim().isNotEmpty) {
      database.addMessage(noteId, messageController.text, false);
      messageController.clear();
      onUpdate();
    }
  }

  /// Микрофон стартует запись; повторное нажатие тоже останавливает и отправляет
  /// (на случай, если где-то ещё используется отдельно от самолётика).
  Future<void> toggleRecording(BuildContext context) async {
    try {
      if (isRecording) {
        await _stopAndSendVoice(context);
      } else {
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) return;
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        currentAmplitudes = [];
        await _audioRecorder.start(const RecordConfig(), path: filePath);
        isRecording = true;

        _ampSub = _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 120))
            .listen((amp) {
          final normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0);
          currentAmplitudes.add(normalized);
          onUpdate();
        });
      }
      onUpdate();
    } catch (e) {
      debugPrint("Error recording: $e");
    }
  }

  /// Останавливает запись, спрашивает подпись (как у фото/видео) и сохраняет
  /// content в формате path|waveform|caption. Подпись необязательна.
  Future<void> _stopAndSendVoice(BuildContext context) async {
    final path = await _audioRecorder.stop();
    await _ampSub?.cancel();
    isRecording = false;
    onUpdate(); // сразу убираем индикатор записи, пока идёт диалог подписи

    if (path == null) {
      currentAmplitudes = [];
      return;
    }

    final waveform = currentAmplitudes.map((e) => e.toStringAsFixed(2)).join(',');
    currentAmplitudes = [];

    final captionController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Голосовое сообщение'),
        content: TextField(
          controller: captionController,
          decoration: const InputDecoration(hintText: 'Подпись (необязательно)...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Отмена = отправить без подписи, а не потерять запись целиком
              await database.addMessage(noteId, "$path|$waveform", false);
              Navigator.pop(context);
              onUpdate();
            },
            child: const Text('Без подписи'),
          ),
          ElevatedButton(
            onPressed: () async {
              final caption = captionController.text.trim();
              final content = caption.isEmpty ? "$path|$waveform" : "$path|$waveform|$caption";
              await database.addMessage(noteId, content, false);
              Navigator.pop(context);
              onUpdate();
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  Future<void> addMedia(BuildContext context, bool isVideo) async {
    final XFile? file = isVideo
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      final commentController = TextEditingController();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isVideo ? 'Видео' : 'Фото'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(hintText: 'Подпись...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                final content = commentController.text.isEmpty
                    ? file.path
                    : "${file.path}|${commentController.text}";
                database.addMessage(noteId, content, isVideo);
                Navigator.pop(context);
              },
              child: const Text('ОК'),
            ),
          ],
        ),
      );
    }
  }

  void dispose() {
    _ampSub?.cancel();
    messageController.dispose();
    _audioRecorder.dispose();
  }
}