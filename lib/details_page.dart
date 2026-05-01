import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:io';
import 'main.dart'; // Убедись, что здесь доступен объект database
import 'database.dart';

class NoteDetailsScreen extends StatefulWidget {
  final Note note;
  const NoteDetailsScreen({super.key, required this.note});

  @override
  State<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Set<int> selectedMessageIds = {};
  bool isSelectionMode = false;
  List<Message> _currentMessages = [];

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

  void openFullScreenImage(String path) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: InteractiveViewer(child: Image.file(File(path)))),
      ),
    ));
  }

  Widget _buildMessageContent(Message msg) {
    final parts = msg.content.split('|');
    final String path = parts[0];
    final String? comment = parts.length > 1 ? parts[1] : null;
    bool isFilePath = path.startsWith('/');

    if (msg.isVideo) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ОБНОВЛЕНО: передаем ID и сохраненную позицию
        VideoPreview(
            msgId: msg.id,
            videoPath: path,
            initialPosition: msg.position, // Теперь плеер знает, где остановился
            isFullScreen: false
        ),
        if (comment != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(comment, style: const TextStyle(fontSize: 15))),
      ]);
    } else if (isFilePath) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => isSelectionMode ? toggleSelection(msg.id) : openFullScreenImage(path),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(path), height: 200, width: double.infinity, fit: BoxFit.cover)),
        ),
        if (comment != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(comment, style: const TextStyle(fontSize: 15))),
      ]);
    }
    return Text(msg.content, style: const TextStyle(fontSize: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isSelectionMode ? 'Выбрано: ${selectedMessageIds.length}' : widget.note.content),
        backgroundColor: isSelectionMode ? Colors.orange.shade100 : Colors.blue.shade100,
        actions: [
          if (isSelectionMode && selectedMessageIds.length == 1)
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => changeMessage(_currentMessages.firstWhere((m) => m.id == selectedMessageIds.first))),
          if (isSelectionMode)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: deleteSelectedMessages),
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
                  return const Center(child: Text("Сообщений пока нет", style: TextStyle(color: Colors.grey)));
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                        ),
                        child: _buildMessageContent(msg),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (!isSelectionMode) SafeArea(child: _buildInputPanel()),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12))
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: () => addMedia(false)),
          IconButton(icon: const Icon(Icons.videocam, color: Colors.redAccent), onPressed: () => addMedia(true)),
          Expanded(
              child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Сообщение...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                  )
              )
          ),
          const SizedBox(width: 4),
          CircleAvatar(
              backgroundColor: Colors.blue,
              child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: sendMessage)
          ),
        ],
      ),
    );
  }
}

// --- ВИДЖЕТ ПЛЕЕРА С ПАМЯТЬЮ ПОЗИЦИИ ---
class VideoPreview extends StatefulWidget {
  final int msgId;
  final String videoPath;
  final int initialPosition;
  final bool isFullScreen;
  final VideoPlayerController? controller; // Добавили возможность передать контроллер

  const VideoPreview({
    super.key,
    required this.msgId,
    required this.videoPath,
    this.initialPosition = 0,
    this.isFullScreen = false,
    this.controller,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Если нам передали готовый контроллер (из превью в фуллскрин) - используем его
    if (widget.controller != null) {
      _controller = widget.controller!;
      _initialized = true;
    } else {
      // Иначе создаем новый
      _controller = VideoPlayerController.file(File(widget.videoPath))
        ..initialize().then((_) {
          if (widget.initialPosition > 0) {
            _controller.seekTo(Duration(seconds: widget.initialPosition));
          }
          setState(() => _initialized = true);
        });
    }

    if (widget.isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _savePosition() {
    if (_initialized) {
      database.updateVideoPosition(widget.msgId, _controller.value.position.inSeconds);
    }
  }

  @override
  void dispose() {
    _savePosition();
    // Закрываем контроллер только если это НЕ переход в фуллскрин
    if (!widget.isFullScreen && widget.controller == null) {
      _controller.dispose();
    }
    if (widget.isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator());

    if (widget.isFullScreen) {
      // Внутри метода build в блоке if (widget.isFullScreen)
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            children: [
              // 1. ВИДЕО (теперь на весь экран для корректного зума)
              Positioned.fill(
                child: InteractiveViewer(
                  // Это ключевое свойство, чтобы видео заполняло пустоту при зуме
                  clipBehavior: Clip.none,
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              ),

              // 2. УПРАВЛЕНИЕ (оставляем как есть, поверх видео)
              if (_showControls) ...[
                Container(color: Colors.black26), // Легкое затемнение
                Align(alignment: Alignment.center, child: _buildPlayButton()),

                // Верх лево: Закрыть
                Positioned(
                  top: 20,
                  left: 20,
                  child: SafeArea(
                      child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 35),
                          onPressed: () => Navigator.pop(context)
                      )
                  ),
                ),

                // Низ лево: Повтор
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: IconButton(
                      icon: const Icon(Icons.replay, color: Colors.white, size: 30),
                      onPressed: () => _controller.seekTo(Duration.zero)
                  ),
                ),

                // Низ центр: Прогресс
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: VideoProgressIndicator(_controller, allowScrubbing: true),
                ),
              ]
            ],
          ),
        ),
      );
    }

    // ОБЫЧНЫЙ РЕЖИМ (ПРЕВЬЮ)
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              _buildPlayButton(),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(_controller, allowScrubbing: true),
              ),
              // Кнопка фуллскрина
              Positioned(
                top: 5,
                right: 5,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white70),
                  onPressed: () {
                    _savePosition();
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => VideoPreview(
                            msgId: widget.msgId,
                            videoPath: widget.videoPath,
                            controller: _controller, // ПЕРЕДАЕМ ТОТ ЖЕ КОНТРОЛЛЕР
                            isFullScreen: true
                        )
                    )).then((_) => setState(() {})); // Обновляем превью после возврата
                  },
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return IconButton(
      iconSize: widget.isFullScreen ? 80 : 50,
      icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white.withOpacity(0.8)),
      onPressed: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
          _savePosition();
        });
      },
    );
  }
}