/// Компактное описание одного медиафайла для навигации между
/// фото/видео в полноэкранном просмотре: путь на диске, id сообщения
/// в БД (нужен для сохранения позиции просмотра) и сохранённая позиция.
class MediaItem {
  final String path;
  final int msgId;
  final int initialPosition;

  const MediaItem({
    required this.path,
    required this.msgId,
    this.initialPosition = 0,
  });
}