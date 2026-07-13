import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// голосовые сообщения
class VoiceMessagePlayer extends StatefulWidget {
  final String path;
  final List<double> waveform; // новое — амплитуды записи для отрисовки волны

  const VoiceMessagePlayer({
    super.key,
    required this.path,
    this.waveform = const [],
  });

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
    _player.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero; // возвращаем волну к началу после проигрывания
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(DeviceFileSource(widget.path));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _seekToTap(double dx, double width) {
    if (_duration == Duration.zero) return;
    final ratio = (dx / width).clamp(0.0, 1.0);
    _player.seek(_duration * ratio);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : _position.inMilliseconds / _duration.inMilliseconds;

    return Row(
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _togglePlay,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              // тап по волне — перемотка на нужное место, как в WhatsApp/Telegram
              onTapDown: (d) => _seekToTap(d.localPosition.dx, constraints.maxWidth),
              child: SizedBox(
                height: 32,
                child: CustomPaint(
                  painter: WaveformPainter(
                    amplitudes: widget.waveform,
                    progress: progress,
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
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

/// Рисует полоски волны как в WhatsApp/Telegram.
/// amplitudes — список амплитуд 0..1, собранных во время записи.
/// progress — доля прослушанного (0..1), чтобы красить "пройденные" бары другим цветом.
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final List<double> amplitudes;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  static const double _barWidth = 3;
  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final barCount = (size.width / (_barWidth + _gap)).floor().clamp(1, amplitudes.length);
    final bars = amplitudes.length <= barCount
        ? amplitudes
        : _resample(amplitudes, barCount);

    final activePaint = Paint()..color = activeColor;
    final inactivePaint = Paint()..color = inactiveColor;
    final progressIndex = (bars.length * progress).floor();

    for (var i = 0; i < bars.length; i++) {
      final x = i * (_barWidth + _gap);
      final barHeight = (bars[i] * size.height).clamp(3.0, size.height);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + _barWidth / 2, size.height / 2),
          width: _barWidth,
          height: barHeight,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, i <= progressIndex ? activePaint : inactivePaint);
    }
  }

  /// Сжимает произвольное число амплитуд до нужного количества баров,
  /// беря максимум в каждом "бакете" — так волна выглядит живее, чем при усреднении.
  List<double> _resample(List<double> source, int targetCount) {
    final bucketSize = source.length / targetCount;
    return List.generate(targetCount, (i) {
      final start = (i * bucketSize).floor();
      final end = ((i + 1) * bucketSize).floor().clamp(start + 1, source.length);
      return source.sublist(start, end).reduce((a, b) => a > b ? a : b);
    });
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes || oldDelegate.progress != progress;
  }
}