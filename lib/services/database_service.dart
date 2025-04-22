import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/map_section.dart';
import '../models/map_content.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return openDatabase(
      path,
      version: 5,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE map_content ADD COLUMN file_name TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE map_content ADD COLUMN document_id INTEGER');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE map_content ADD COLUMN section_id INTEGER');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE map_content ADD COLUMN hash TEXT');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
         CREATE TABLE map_content (
           id INTEGER PRIMARY KEY,
           section_id INTEGER,
           hash TEXT,
           file_name TEXT,
           status INTEGER,
           document_id INTEGER,
           text_inspection TEXT,
           status_inspection INTEGER
         )
       ''');

        await db.execute('''
         CREATE TABLE map_section (
           id INTEGER PRIMARY KEY,
           name TEXT,
           description TEXT
         )
       ''');
      },
    );
  }

  Future<void> insertContentToSection(int sectionId, List<MapContent> contents) async {
    final db = await database;
    for (var content in contents) {
      content.sectionId = sectionId;
      await db.insert(
        'map_content',
        content.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> updateVideoUrl(int sectionId, String url) async {
    final db = await database;
    await db.update(
      'map_content',
      {'url': url},
      where: 'section_id = ?',
      whereArgs: [sectionId],
    );
  }

  Future<List<MapContent>> getPendingContents() async {
    final db = await database;
    final maps = await db.query(
      'map_content',
      where: 'status = ? AND section_id != ?',
      whereArgs: [0, 37], // 0 - не отправленные, 1000 - id секции видео
    );
    debugPrint('Pending contents: ${maps.length}'); // Для отладки
    return maps.map((m) => MapContent.fromJson(m)).toList();
  }

  Future<List<MapContent>> getPendingVideoContents() async {
    final db = await database;
    final maps = await db.query(
      'map_content',
      where: 'status = ? AND section_id = ?',
      whereArgs: [0, 37], // Только видео файлы
    );
    debugPrint('Pending video contents: ${maps.length}'); // Для отладки
    return maps.map((m) => MapContent.fromJson(m)).toList();
  }

  Future<List<MapContent>> getAllPendingContents() async {
    final db = await database;
    final maps = await db.query(
      'map_content',
      where: 'status = ?',
      whereArgs: [0], // NOT_SENT
    );
    return maps.map((m) => MapContent.fromJson(m)).toList();
  }

  Future<void> updateUid(int contentId, String newUid) async {
    final db = await database;
    await db.update(
      'map_content',
      {'hash': newUid},
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }

  Future<List<MapContent>> getContentsForSection(int sectionId) async {
    final db = await database;
    final maps = await db.query(
      'map_content',
      where: 'section_id = ?',
      whereArgs: [sectionId],
    );
    return maps.map((m) => MapContent.fromJson(m)).toList();
  }

  Future<void> updateContentStatus(int id, int status, {String? statusText}) async {
    final db = await database;
    await db.update(
      'map_content',
      {
        'status': status,
        'text_inspection': statusText,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> resetAllContentStatus() async {
    final db = await database;
    await db.update(
      'map_content',
      {'status': 0},
    );
  }

  Future<void> deleteContent(int id) async {
    final db = await database;
    await db.delete(
      'map_content',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete('map_content');
    await db.delete('map_section');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}