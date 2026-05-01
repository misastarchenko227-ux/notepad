import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer()(); // Ссылка на ID заметки
  TextColumn get content => text()();
  BoolColumn get isVideo => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [Notes, Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  // === ДОБАВЬ ЭТИ МЕТОДЫ СЮДА ===

  // 1. Чтение (Stream аналог LiveData)
  Stream<List<Note>> watchAllNotes() => select(notes).watch();

  // 2. Добавление (Аналог @Insert)
  Future<int> addNote(String content) {
    return into(notes).insert(NotesCompanion.insert(content: content));
  }

  // 3. Удаление (Аналог @Delete)
  Future<int> deleteNote(Note note) {
    return delete(notes).delete(note);
  }
  // Исправленный метод
  Stream<List<Message>> watchMessagesForNote(int noteId) {
    return (select(messages)..where((t) => t.noteId.equals(noteId))).watch();
  }

  // Добавь метод вставки, если его нет
  Future<int> addMessage(int noteId, String content, bool isVideo) {
    return into(messages).insert(MessagesCompanion.insert(
      noteId: noteId,
      content: content,
      isVideo: Value(isVideo),
    ));
  }
  Future<int> deleteMessageById(int id) {
    return (delete(messages)..where((t) => t.id.equals(id))).go();
  }

  // Удаление списка сообщений (для массового удаления)
  Future<void> deleteMessagesByIds(Set<int> ids) async {
    await (delete(messages)..where((t) => t.id.isIn(ids))).go();
  }
  Future<int> updateMessageContent(int id, String newContent) {
    return (update(messages)..where((t) => t.id.equals(id)))
        .write(MessagesCompanion(content: Value(newContent)));
  }
  Future updateVideoPosition(int id, int position) {
    return (update(messages)..where((t) => t.id.equals(id)))
        .write(MessagesCompanion(position: Value(position)));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}