import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/map_section.dart';

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
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE map_section(id INTEGER PRIMARY KEY, name TEXT, description TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<void> insertMapSection(MapSection section) async {
    final db = await database;
    await db.insert(
      'map_section',
      section.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MapSection>> getMapSections() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('map_section');
    return List.generate(maps.length, (i) {
      return MapSection.fromJson(maps[i]);
    });
  }
}