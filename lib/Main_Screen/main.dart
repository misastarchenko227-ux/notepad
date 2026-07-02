import 'package:flutter/material.dart';
import 'package:notepad/Advertisement/ad_screen.dart';
import 'package:notepad/Input_Panel/Note_Details_Screen.dart';
import 'package:notepad/Privacy_policy/Privacy_policy.dart';
import 'package:notepad/Privacy_policy/privacy_policy_screen.dart';


import 'package:provider/provider.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Favorites_Screen/Favorites_Screen.dart';
import 'package:notepad/Run_App/Run_App.dart';
import 'package:notepad/Search/Search.dart';

late AppDatabase database;

class MyNotesPage extends StatefulWidget {
  const MyNotesPage({super.key});

  @override
  State<MyNotesPage> createState() => _MyNotesPageState();
}

class _MyNotesPageState extends State<MyNotesPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void saveMessage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = Provider.of<ThemeSettings>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Поиск заметки...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                ),
                style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('Блокнот'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicyScreen(
                    sections: PrivacyPolicyContent.sections,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              themeSettings.currentMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () => themeSettings.toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (!snapshot.hasData) {
                        return const Center(child: Text('Ошибка загрузки данных'));
                      }
                      
                      final allNotes = snapshot.data!;
                      
                      // Используем вынесенную логику фильтрации
                      final notes = NoteSearch.filter(allNotes, _searchQuery);

                      if (allNotes.isEmpty) {
                        return const Center(child: Text('Заметок пока нет'));
                      }
                      
                      if (notes.isEmpty && _searchQuery.isNotEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: colorScheme.outline),
                              const SizedBox(height: 16),
                              Text(
                                'Ничего не найдено',
                                style: TextStyle(color: colorScheme.outline, fontSize: 18),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final item = notes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: ListTile(
                              title: Text(item.content),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => database.deleteNote(item),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NoteDetailsScreen(note: item),
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
          ),
          const SafeArea(
            top: false,
            child: MiniBannerAd(),
          ),
        ],
      ),
    );
  }
}
