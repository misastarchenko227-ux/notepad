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
  IntColumn get noteId => integer()();
  TextColumn get content => text()();
  BoolColumn get isVideo => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get groupId => integer().nullable()();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class MessageWithNote {
  final Message message;
  final Note note;
  MessageWithNote(this.message, this.note);
}

@DriftDatabase(tables: [Notes, Messages, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 7) {
          try {
            await m.addColumn(messages, messages.isFavorite);
          } catch (e) {
            print("Migration info: Column isFavorite already exists.");
          }
        }
      },
    );
  }

  Stream<List<MessageWithNote>> watchFavoriteMessagesWithNotes() {
    final query = select(messages).join([
      innerJoin(notes, notes.id.equalsExp(messages.noteId)),
    ]);

    query.where(messages.isFavorite.equals(true));

    return query.watch().map((rows) {
      return rows.map((row) {
        return MessageWithNote(
          row.readTable(messages),
          row.readTable(notes),
        );
      }).toList();
    });
  }

  Stream<List<Note>> watchAllNotes() => select(notes).watch();

  Future<int> addNote(String content) {
    return into(notes).insert(NotesCompanion.insert(content: content));
  }

  Future<void> toggleFavorite(Message message) {
    return (update(messages)..where((t) => t.id.equals(message.id)))
        .write(MessagesCompanion(isFavorite: Value(!message.isFavorite)));
  }

  Stream<List<Message>> watchFavoriteMessages() {
    return (select(messages)..where((t) => t.isFavorite.equals(true))).watch();
  }

  Stream<List<Message>> watchFavoritesForNote(int noteId) {
    return (select(messages)
      ..where((t) => t.noteId.equals(noteId))
      ..where((t) => t.isFavorite.equals(true))
    ).watch();
  }

  Future<bool> isDarkMode() async {
    final row = await (select(settings)..where((t) => t.key.equals('is_dark_mode'))).getSingleOrNull();
    if (row == null) return false;
    return row.value == 'true';
  }

  Future<void> saveTheme(bool isDark) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(
        key: 'is_dark_mode',
        value: isDark.toString(),
      ),
    );
  }

  Future<int> deleteNote(Note note) {
    return delete(notes).delete(note);
  }

  /// Удаляет заметку и все связанные с ней файлы сообщений
  Future<void> deleteNoteWithFiles(Note note) async {
    // Получаем все сообщения этой заметки
    final noteMessages = await (select(messages)..where((t) => t.noteId.equals(note.id))).get();
    
    // Удаляем физические файлы
    for (var msg in noteMessages) {
      final path = msg.content.split('|').first;
      if (path.isNotEmpty && (path.contains('/') || path.contains('\\'))) {
        final file = File(path);
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print("Ошибка при удалении файла: $e");
        }
      }
    }
    
    // Удаляем сообщения и саму заметку из БД
    await (delete(messages)..where((t) => t.noteId.equals(note.id))).go();
    await delete(notes).delete(note);
  }

  Stream<List<Message>> watchMessagesForNote(int noteId) {
    return (select(messages)..where((t) => t.noteId.equals(noteId))).watch();
  }

  Future<int> addMessage(int noteId, String content, bool isVideo, {int? groupId}) {
    return into(messages).insert(MessagesCompanion.insert(
      noteId: noteId,
      content: content,
      isVideo: Value(isVideo),
      groupId: Value(groupId),
    ));
  }

  Future<int> deleteMessageById(int id) {
    return (delete(messages)..where((t) => t.id.equals(id))).go();
  }

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
