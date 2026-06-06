import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Favorites_Screen/Message_Content.dart';
import 'package:notepad/Main_Functions/Photo/Full_Screen_Image.dart';
import 'package:notepad/Main_Screen/main.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  bool _isMedia(Message msg) {
    if (msg.isVideo) return true;
    final path = msg.content.split('|')[0].toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<MessageWithNote>>(
        stream: database.watchFavoriteMessagesWithNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Text(
                "Здесь пока ничего нет",
                style: TextStyle(color: colorScheme.outline),
              ),
            );
          }

          // Собираем все пути к медиафайлам из текущего списка избранного
          final mediaMessages = items.where((item) => _isMedia(item.message)).toList();
          final allMediaPaths = mediaMessages
              .map((item) => item.message.content.split('|')[0])
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final msg = item.message;
              final note = item.note;

              // Находим индекс текущего сообщения в общем списке медиа
              int? mediaIndex;
              if (_isMedia(msg)) {
                mediaIndex = mediaMessages.indexOf(item);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MessageContent(
                      msg: msg,
                      mediaPaths: allMediaPaths,
                      mediaIndex: mediaIndex,
                      onImageTap: () {
                        if (mediaIndex != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Full_Screen_Image(
                                paths: allMediaPaths,
                                initialIndex: mediaIndex!,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Из заметки: ${note.content}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueAccent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.star, color: Colors.amber, size: 22),
                          onPressed: () async {
                            await database.toggleFavorite(msg);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Удалено из избранного"),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
