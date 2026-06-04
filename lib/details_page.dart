import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';
import 'Data_Base/database.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'VideoPreview.dart';
import 'VoiceMessagePlayer.dart';
import 'PhotoPreview.dart'; // <--- ДОБАВИЛИ ИМПОРТ НОВОГО КЛАССА

class NoteDetailsScreen extends StatefulWidget {
  final Note note;
  const NoteDetailsScreen({super.key, required this.note});

  @override
  State<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  Set<int> selectedMessageIds = {};
  bool isSelectionMode = false;
  List<Message> _currentMessages = [];

  // --- НОВЫЙ МЕТОД ДЛЯ ИЗБРАННОГО ---
  void toggleSelectedFavorites() async {
    for (var id in selectedMessageIds) {
      final msg = _currentMessages.firstWhere((m) => m.id == id);
      await database.toggleFavorite(msg);
    }
    setState(() {
      isSelectionMode = false;
      selectedMessageIds.clear();
    });
  }

  void toggleSelection(int id) {
    setState(() {
      if (selectedMessageIds.contains(id)) {
        selectedMessageIds.remove(id);
        if (selectedMessageIds.isEmpty) isSelectionMode = false;
      } else {
        selectedMessageIds.add(id);
        isSelectionMode = true;
      }
    });
  }

  void deleteSelectedMessages() async {
    await database.deleteMessagesByIds(selectedMessageIds);
    setState(() {
      selectedMessageIds.clear();
      isSelectionMode = false;
    });
  }

  void changeMessage(Message msg) async {
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
              String newContent = msg.isVideo ? "${parts[0]}|${editController.text}" : editController.text;
              if (newContent.isNotEmpty) {
                await database.updateMessageContent(msg.id, newContent);
                if (mounted) Navigator.pop(context);
                setState(() {
                  isSelectionMode = false;
                  selectedMessageIds.clear();
                });
              }
            },
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  void sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      database.addMessage(widget.note.id, _messageController.text, false);
      _messageController.clear();
    }
  }

  Future<void> voice() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null) {
          await database.addMessage(widget.note.id, path, false);
        }
      } else {
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) return;

        final directory = await getApplicationDocumentsDirectory();
        final String filePath = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: filePath);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint("Error recording: $e");
    }
  }

  Future<void> addMedia(bool isVideo) async {
    final XFile? file = isVideo
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      final TextEditingController commentController = TextEditingController();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isVideo ? 'Видео' : 'Фото'),
          content: TextField(controller: commentController, decoration: const InputDecoration(hintText: 'Подпись...')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                final String content = commentController.text.isEmpty ? file.path : "${file.path}|${commentController.text}";
                database.addMessage(widget.note.id, content, isVideo);
                Navigator.pop(context);
              },
              child: const Text('ОК'),
            ),
          ],
        ),
      );
    }
  }

  // --- МЕТОД openFullScreenImage УДАЛЕН, ТАК КАК ОН ТЕПЕРЬ ВНУТРИ КЛАССА PhotoPreview ---

  Widget _buildMessageContent(Message msg, ColorScheme colorScheme) {
    final parts = msg.content.split('|');
    final String path = parts[0];
    final String? comment = parts.length > 1 ? parts[1] : null;
    bool isFilePath = path.startsWith('/');

    TextStyle textStyle = TextStyle(fontSize: 16, color: colorScheme.onSurface);

    if (path.endsWith('.m4a') || path.endsWith('.wav')) {
      return VoiceMessagePlayer(path: path);
    }

    if (msg.isVideo) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VideoPreview(
            msgId: msg.id,
            videoPath: path,
            initialPosition: msg.position,
            isFullScreen: false
        ),
        if (comment != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(comment, style: textStyle)),
      ]);
    } else if (isFilePath) {
      // --- ИСПОЛЬЗУЕМ ТВОЙ НОВЫЙ КЛАСС ТУТ ---
      return PhotoPreview(
        msgId: msg.id,
        photoPath: path,
        comment: comment,
        isSelectionMode: isSelectionMode,
        onLongPress: () => toggleSelection(msg.id),
        onTapInSelection: () => toggleSelection(msg.id),
      );
    }
    return Text(msg.content, style: textStyle);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          isSelectionMode ? 'Выбрано: ${selectedMessageIds.length}' : widget.note.content,
          style: TextStyle(color: isSelectionMode ? colorScheme.onSecondaryContainer : colorScheme.onSurface),
        ),
        backgroundColor: isSelectionMode
            ? colorScheme.secondaryContainer
            : (isDark ? colorScheme.surface : Colors.blue.shade100),
        elevation: 0,
        actions: [
          if (isSelectionMode) ...[
            // КНОПКА ИЗБРАННОГО
            IconButton(
              icon: Icon(
                selectedMessageIds.every((id) => _currentMessages.firstWhere((m) => m.id == id).isFavorite)
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: toggleSelectedFavorites,
            ),
            if (selectedMessageIds.length == 1)
              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => changeMessage(_currentMessages.firstWhere((m) => m.id == selectedMessageIds.first))),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: deleteSelectedMessages),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: database.watchMessagesForNote(widget.note.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                _currentMessages = snapshot.data!;

                if (_currentMessages.isEmpty) {
                  return Center(child: Text("Сообщений пока нет", style: TextStyle(color: colorScheme.outline)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _currentMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _currentMessages[index];
                    final isSelected = selectedMessageIds.contains(msg.id);
                    return GestureDetector(
                      onLongPress: () => toggleSelection(msg.id),
                      onTap: () => isSelectionMode ? toggleSelection(msg.id) : null,
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
                                    offset: const Offset(0, 2)
                                )
                              ],
                            ),
                            child: _buildMessageContent(msg, colorScheme),
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
                  },
                );
              },
            ),
          ),
          if (!isSelectionMode) SafeArea(child: _buildInputPanel(context)),
        ],
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5))
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: _isRecording ? Colors.red : colorScheme.primary),
            onPressed: voice,
          ),
          IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: () => addMedia(false)),
          IconButton(icon: const Icon(Icons.videocam, color: Colors.redAccent), onPressed: () => addMedia(true)),
          Expanded(
              child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Сообщение',
                    hintStyle: TextStyle(color: colorScheme.outline),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: isDark ? colorScheme.surfaceVariant.withOpacity(0.4) : Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  )
              )
          ),
          const SizedBox(width: 4),
          CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: sendMessage)
          ),
        ],
      ),
    );
  }
}