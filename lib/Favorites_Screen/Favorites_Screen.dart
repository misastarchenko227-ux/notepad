import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Favorites_Screen/Message_Content.dart';
import 'package:notepad/Main_Functions/Photo/Full_Screen_Image.dart';
import 'package:notepad/Main_Screen/main.dart';


class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  void _openImage(BuildContext context, String fullContent) {
    final String path = fullContent.split('|')[0];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Full_Screen_Image(
          paths: [path],     // ← только одно фото, без скролла
          initialIndex: 0,
        ),
      ),
    );
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

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final msg = item.message;
              final note = item.note;

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
                      onImageTap: () => _openImage(context, msg.content),
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
                        // ЗАМЕНА: Теперь это IconButton, чтобы можно было нажать
                        IconButton(
                          constraints: const BoxConstraints(), // Убираем лишние отступы
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.star, color: Colors.amber, size: 22),
                          onPressed: () async {
                            // Вызываем метод переключения избранного из database.dart
                            await database.toggleFavorite(msg);

                            // Опционально: показать небольшое уведомление
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