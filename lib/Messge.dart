import 'package:uuid/uuid.dart'; // Рекомендую пакет uuid для генерации ID

class ChatMessage {
  final String id;
  final String text;
  final bool isVideo; // Флаг, сообщение это или видео

  ChatMessage({
    required this.id,
    required this.text,
    this.isVideo = false,
  });
}