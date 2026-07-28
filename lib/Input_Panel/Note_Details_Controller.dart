import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Main_Screen/main.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';


class NoteDetailsController {
  final int noteId;
  final VoidCallback onUpdate;

  final TextEditingController messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  StreamSubscription<Amplitude>? _ampSub;
  List<double> currentAmplitudes = [];
  String? _currentRecordingPath; // новое — нужен путь, чтобы удалить файл при отмене

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

  /// Микрофон стартует запись. Пока идёт запись, эта кнопка больше не используется
  /// для остановки — за это отвечают sendMessage (отправить) и cancelRecording (удалить).
  Future<void> toggleRecording(BuildContext context) async {
    if (isRecording) return; // пока пишем — кнопка микрофона неактивна, см. InputPanel
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) return;
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      currentAmplitudes = [];
      _currentRecordingPath = filePath;
      await _audioRecorder.start(const RecordConfig(), path: filePath);
      isRecording = true;

      _ampSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amp) {
        final normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0);
        currentAmplitudes.add(normalized);
        onUpdate();
      });
      onUpdate();
    } catch (e) {
      debugPrint("Error recording: $e");
    }
  }

  /// Отменяет текущую запись: останавливает рекордер, удаляет недописанный
  /// файл с диска и сбрасывает состояние — сообщение никуда не отправляется.
  Future<void> cancelRecording() async {
    if (!isRecording) return;
    await _audioRecorder.stop();
    await _ampSub?.cancel();
    isRecording = false;

    final path = _currentRecordingPath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    currentAmplitudes = [];
    _currentRecordingPath = null;
    onUpdate();
  }

  /// Останавливает запись, спрашивает подпись (как у фото/видео) и сохраняет
  /// content в формате path|waveform|caption. Подпись необязательна.
  Future<void> _stopAndSendVoice(BuildContext context) async {
    final path = await _audioRecorder.stop();
    await _ampSub?.cancel();
    isRecording = false;
    _currentRecordingPath = null;
    onUpdate();

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

  /// Открывает системную галерею в режиме множественного выбора (фото и видео
  /// вперемешку, без ограничения по количеству — как альбом в Telegram).
  /// Одна подпись на весь пакет, привязывается к последнему файлу.

  Future<void> addMedia(BuildContext context) async {
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 9999, // условно "без ограничений"
        requestType: RequestType.common, // фото и видео вместе
        themeColor: Colors.blue,
        // светлая тема гарантированно, независимо от устройства
        pickerTheme: null,
      ),
    );

    if (assets == null || assets.isEmpty) return;

    final commentController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Отправить ${assets.length} файл(ов)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 70,
                          height: 90,
                          // виджет пакета сам достаёт превью из галереи
                          child: AssetEntityImage(
                            asset,
                            isOriginal: false,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (asset.type == AssetType.video)
                          const Positioned(
                            right: 4,
                            bottom: 4,
                            child: Icon(Icons.videocam, color: Colors.white, size: 18),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(hintText: 'Подпись...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for (var i = 0; i < assets.length; i++) {
      final asset = assets[i];
      final File? file = await asset.file; // достаём реальный путь на диске
      if (file == null) continue;

      final isVideo = asset.type == AssetType.video;
      final isLast = i == assets.length - 1;

      final content = (isLast && commentController.text.isNotEmpty)
          ? "${file.path}|${commentController.text}"
          : file.path;

      await database.addMessage(noteId, content, isVideo);
    }
    onUpdate();
  }
  /// Определяет, видео это или фото. Сначала смотрим mimeType от пикера
  /// (на Android/iOS почти всегда заполнен), если пусто — по расширению файла.
  bool _isVideoFile(XFile file) {
    final mime = file.mimeType;
    if (mime != null) return mime.startsWith('video/');

    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv') ||
        path.endsWith('.webm');
  }

  void dispose() {
    _ampSub?.cancel();
    messageController.dispose();
    _audioRecorder.dispose();
  }
}