
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
// голосовые сообщения
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