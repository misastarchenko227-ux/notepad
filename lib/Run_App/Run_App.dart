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
  try {
    await database.select(database.notes).get();
  } catch (e) {
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
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      themeMode: themeSettings.currentMode,
      home: const UnicoreLoadingScreen(),
    );
  }
}
