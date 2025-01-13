import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/map_section.dart';
import '../models/map_content.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return openDatabase(
      path,
      version: 3, // Увеличиваем версию БД
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE map_content ADD COLUMN file_name TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE map_content ADD COLUMN document_id INTEGER');
        }
      },
      onCreate: (db, version) async {
        // Создание таблицы map_content
        await db.execute(
          "CREATE TABLE map_content ("
              "id INTEGER PRIMARY KEY, "
              "file_name TEXT, "
              "status INTEGER, "
              "document_id INTEGER, "
              "text_inspection TEXT, "
              "status_inspection INTEGER"
              ")",
        );

        // Создание таблицы map_section
        await db.execute(
          "CREATE TABLE map_section ("
              "id INTEGER PRIMARY KEY, "
              "name TEXT, "
              "description TEXT"
              ")",
        );
      },
    );
  }

  // Вставка содержимого (фото) в секцию
  Future<void> insertContentToSection(int sectionId, List<MapContent> contents) async {
    final db = await database;
    for (var content in contents) {
      await db.insert(
        'map_content',
        content.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Получение всех содержимых для секции
  Future<List<MapContent>> getContentsForSection(int sectionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'map_content',
      where: 'id = ?',
      whereArgs: [sectionId],
    );

    return List.generate(maps.length, (i) {
      return MapContent.fromJson(maps[i]);
    });
  }

  // Обновление статуса содержимого
  Future<void> updateContentStatus(int id, int status) async {
    final db = await database;
    await db.update(
      'map_content',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Удаление содержимого (фото) по ID
  Future<void> deleteContent(int id) async {
    final db = await database;
    await db.delete(
      'map_content',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}