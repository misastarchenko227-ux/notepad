import 'package:notepad/Data_Base/database.dart';

class NoteSearch {
  /// Логика фильтрации заметок по поисковому запросу
  static List<Note> filter(List<Note> allNotes, String query) {
    if (query.isEmpty) {
      return allNotes;
    }
    
    final lowerQuery = query.toLowerCase().trim();
    return allNotes.where((note) {
      final content = note.content.toLowerCase();
      return content.contains(lowerQuery);
    }).toList();
  }
}
