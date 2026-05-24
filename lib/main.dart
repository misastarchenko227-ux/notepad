import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'database.dart';
import 'details_page.dart';
import 'saveMessage.dart';
import 'ad_screen.dart'; // Здесь должен лежать наш MiniBannerAd
import 'loading_screen.dart';

late AppDatabase database;

class ThemeSettings extends ChangeNotifier {
  bool _isDark = false;
  ThemeSettings() { _loadFromDb(); }
  bool get isDark => _isDark;
  ThemeMode get currentMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadFromDb() async {
    _isDark = await database.isDarkMode();
    notifyListeners();
  }

  void toggleTheme() async {
    _isDark = !_isDark;
    await database.saveTheme(_isDark);
    notifyListeners();
  }
}

 Future <void> main()async {
  WidgetsFlutterBinding.ensureInitialized();
  database = AppDatabase();
try{
  await database.select(database.notes).get();
} catch(e){
  ScaffoldMessenger.of(context as BuildContext).showSnackBar(
    SnackBar(
      content: Text("Ошибка БД: $e"),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 20),
    ),
  );
}
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeSettings(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSettings = Provider.of<ThemeSettings>(context);

    return MaterialApp(
      title: 'Flutter Notepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: themeSettings.currentMode,
      home: const UnicoreLoadingScreen(),
    );
  }
}

class MyNotesPage extends StatefulWidget {
  const MyNotesPage({super.key});
  @override
  State<MyNotesPage> createState() => _MyNotesPageState();
}

class _MyNotesPageState extends State<MyNotesPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void saveMessage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = Provider.of<ThemeSettings>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Блокнот'),
        actions: [
          IconButton(
            icon: Icon(themeSettings.currentMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => themeSettings.toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. ОСНОВНОЙ КОНТЕНТ (Обернут в Expanded)
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(labelText: 'Текст заметки', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        mini: true,
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            database.addNote(_controller.text);
                            _controller.clear();
                          }
                        },
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => saveMessage(context),
                  child: const Text("Избранные сообщения!"),
                ),
                Expanded(
                  child: StreamBuilder<List<Note>>(
                    stream: database.watchAllNotes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final notes = snapshot.data!;
                      if (notes.isEmpty) return const Center(child: Text('Заметок пока нет'));
                      return ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final item = notes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              title: Text(item.content),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => database.deleteNote(item),
                              ),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailsScreen(note: item)));
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
          ),

          // 2. БАННЕР ВНИЗУ (Всегда виден под контентом)
          const MiniBannerAd(),
        ],
      ),
    );
  }
}