import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notepad/Data_Base/database.dart';
import 'package:notepad/Loading/loading_screen.dart';
import 'package:notepad/Main_Screen/main.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  database = AppDatabase();

  bool dbOk = true;
  try {
    await database.select(database.notes).get();
  } catch (e) {
    dbOk = false;
    debugPrint("Ошибка БД: $e"); // ← было: попытка показать SnackBar через несуществующий context
  }

  final bool hasSeenOnboarding = await database.hasSeenOnboarding(); // ← новое

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeSettings(),
      child: MyApp(
        showOnboarding: !hasSeenOnboarding, // ← новое
        dbErrorOccurred: !dbOk, // ← новое: передаём дальше, чтобы показать ошибку уже внутри дерева виджетов
      ),
    ),
  );
}

class ThemeSettings extends ChangeNotifier {
  bool _isDark = false;

  ThemeSettings() {
    _loadFromDb();
  }

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

class MyApp extends StatelessWidget {
  final bool showOnboarding; // ← новое
  final bool dbErrorOccurred; // ← новое

  const MyApp({
    super.key,
    required this.showOnboarding, // ← новое
    this.dbErrorOccurred = false, // ← новое
  });

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
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      themeMode: themeSettings.currentMode,
      home: showOnboarding
          ? const UnicoreLoadingScreen() // ← первый запуск — показываем онбординг
          : const MyNotesPage(), // ← повторный запуск — сразу главный экран
      builder: (context, child) {
        // Ошибку БД показываем уже здесь — SnackBar требует контекст
        // внутри дерева MaterialApp, а не сырой контекст main().
        if (dbErrorOccurred) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Ошибка БД"),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 20),
              ),
            );
          });
        }
        return child!;
      },
    );
  }
}