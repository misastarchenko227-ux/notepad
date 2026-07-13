import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// голосовые сообщения
class VoiceMessagePlayer extends StatefulWidget {
  final String path;
  final List<double> waveform;

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

  // новое — состояние протягивания пальцем
  bool _isDragging = false;
  double _dragProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) {
      // пока пользователь тащит палец — игнорируем позицию от плеера,
      // иначе она "перебьёт" визуальное отображение драга
      if (!_isDragging) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
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

  double _ratioFromDx(double dx, double width) => (dx / width).clamp(0.0, 1.0);

  void _seekToTap(double dx, double width) {
    if (_duration == Duration.zero) return;
    _player.seek(_duration * _ratioFromDx(dx, width));
  }

  void _onDragStart(double dx, double width) {
    if (_duration == Duration.zero) return;
    setState(() {
      _isDragging = true;
      _dragProgress = _ratioFromDx(dx, width);
    });
  }

  void _onDragUpdate(double dx, double width) {
    if (_duration == Duration.zero) return;
    // только двигаем волну визуально, без вызова seek — так плавнее
    setState(() => _dragProgress = _ratioFromDx(dx, width));
  }

  void _onDragEnd() {
    if (_duration == Duration.zero) return;
    // перематываем ровно один раз, когда палец отпущен
    _player.seek(_duration * _dragProgress);
    setState(() {
      _position = _duration * _dragProgress;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // во время драга показываем _dragProgress, иначе — реальную позицию плеера
    final progress = _isDragging
        ? _dragProgress
        : (_duration.inMilliseconds == 0
        ? 0.0
        : _position.inMilliseconds / _duration.inMilliseconds);

    final displayedPosition = _isDragging ? _duration * _dragProgress : _position;

    return Row(
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _togglePlay,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapDown: (d) => _seekToTap(d.localPosition.dx, constraints.maxWidth),
              onHorizontalDragStart: (d) => _onDragStart(d.localPosition.dx, constraints.maxWidth),
              onHorizontalDragUpdate: (d) => _onDragUpdate(d.localPosition.dx, constraints.maxWidth),
              onHorizontalDragEnd: (_) => _onDragEnd(),
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
          "${displayedPosition.inMinutes}:${(displayedPosition.inSeconds % 60).toString().padLeft(2, '0')}",
          style: TextStyle(fontSize: 12, color: colorScheme.outline),
        ),
      ],
    );
  }
}

/// Рисует полоски волны как в WhatsApp/Telegram.
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