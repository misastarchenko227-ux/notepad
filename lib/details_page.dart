import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:drift/drift.dart' as drift; // Добавлено для работы с Value
import 'main.dart';
import 'database.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ad_screen.dart';

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

  void openFullScreenImage(String path) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: InteractiveViewer(child: Image.file(File(path)))),
      ),
    ));
  }

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
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => isSelectionMode ? toggleSelection(msg.id) : openFullScreenImage(path),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(path), height: 200, width: double.infinity, fit: BoxFit.cover)),
        ),
        if (comment != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(comment, style: textStyle)),
      ]);
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
                      child: Stack( // Используем Stack, чтобы добавить иконку звезды в углу
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
                          if (msg.isFavorite) // Показываем маленькую звезду, если сообщение в избранном
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

// --- НОВЫЙ ВИДЖЕТ ДЛЯ ПРОСЛУШИВАНИЯ ГС ---
class VoiceMessagePlayer extends StatefulWidget {
  final String path;
  const VoiceMessagePlayer({super.key, required this.path});

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () async {
            if (_isPlaying) {
              await _player.pause();
            } else {
              await _player.play(DeviceFileSource(widget.path));
            }
            setState(() => _isPlaying = !_isPlaying);
          },
        ),
        Expanded(
          child: Slider(
            value: _position.inMilliseconds.toDouble(),
            max: _duration.inMilliseconds.toDouble() > 0
                ? _duration.inMilliseconds.toDouble()
                : 1.0,
            onChanged: (value) async {
              await _player.seek(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
        Text(
          "${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}",
          style: TextStyle(fontSize: 12, color: colorScheme.outline),
        ),
      ],
    );
  }
}

// --- ВИДЖЕТ ПЛЕЕРА ВИДЕО (БЕЗ ИЗМЕНЕНИЙ) ---
class VideoPreview extends StatefulWidget {
  final int msgId;
  final String videoPath;
  final int initialPosition;
  final bool isFullScreen;
  final VideoPlayerController? controller;

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
    if (widget.controller != null) {
      _controller = widget.controller!;
      _initialized = true;
    } else {
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
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
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
              if (_showControls) ...[
                Container(color: Colors.black26),
                Align(alignment: Alignment.center, child: _buildPlayButton()),
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
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: IconButton(
                      icon: const Icon(Icons.replay, color: Colors.white, size: 30),
                      onPressed: () => _controller.seekTo(Duration.zero)
                  ),
                ),
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

    return ClipRRect(
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
                        controller: _controller,
                        isFullScreen: true
                    )
                )).then((_) => setState(() {}));
              },
            ),
          )
        ],
      ),
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