import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, 'file_linksv2.db');

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
    CREATE TABLE file_links (
      id INTEGER PRIMARY KEY,
      file_name TEXT,
      link TEXT,
      delete_token_url TEXT
    )
  ''');
  }

  Future<int> insertFileLink(
      String fileName, String link, String deleteTokenUrl) async {
    final Database db = await instance.database;
    return await db.insert('file_links', {
      'file_name': fileName,
      'link': link,
      'delete_token_url': deleteTokenUrl,
    });
  }

  Future<List<Map<String, dynamic>>> getFileLinks() async {
    final Database db = await instance.database;
    return await db.query('file_links');
  }

  Future<int> deleteFileLink(int id) async {
    final Database db = await instance.database;
    return await db.delete('file_links', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getFileHistory() async {
    final db = await database;
    return await db.query('file_links', orderBy: 'id DESC');
  }
}
