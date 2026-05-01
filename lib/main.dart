import 'package:flutter/material.dart';
import 'database.dart'; // Твой файл с настройками Drift БД
import 'details_page.dart';

// 1. Глобальная переменная для базы (аналог Singleton в Android)
late AppDatabase database;

void main() {
  // Гарантируем инициализацию плагинов Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем БД один раз при запуске
  database = AppDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyNotesPage(),
    );
  }
}

// === ГЛАВНЫЙ ЭКРАН (СПИСОК И ВВОД) ===
class MyNotesPage extends StatefulWidget {
  const MyNotesPage({super.key});

  @override
  State<MyNotesPage> createState() => _MyNotesPageState();
}

class _MyNotesPageState extends State<MyNotesPage> {
  // Контроллер для EditText (TextField)
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose(); // Очищаем память, как в onDestroy
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Блокнот'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          // БЛОК ВВОДА (EditText + Button)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Текст заметки',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      // Вставляем запись в БД (аналог @Insert в Room)
                      database.addNote(_controller.text);
                      _controller.clear();
                    }
                  },
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // БЛОК СПИСКА (аналог RecyclerView + StreamBuilder)
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: database.watchAllNotes(), // Подписка на изменения БД
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notes = snapshot.data!;

                if (notes.isEmpty) {
                  return const Center(child: Text('Заметок пока нет'));
                }

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final item = notes[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(item.content),
                        //subtitle: Text('ID: ${item.id}'),
                        // УДАЛЕНИЕ
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => database.deleteNote(item),
                        ),
                        // ПЕРЕХОД НА ЭКРАН ДЕТАЛЕЙ
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteDetailsScreen(note: item),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


