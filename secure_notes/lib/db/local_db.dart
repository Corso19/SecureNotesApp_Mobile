import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class LocalDB {
  static Database? _database;
  static final _secureStorage = FlutterSecureStorage();

  // 🔒 Generate encryption key securely
  static Future<String> _getEncryptionKey() async {
    String? key = await _secureStorage.read(key: 'db_key');
    if (key == null) {
      key = List.generate(32, (i) => (65 + i).toRadixString(16)).join();dsadasdasda
      await _secureStorage.write(key: 'db_key', value: key);
    }
    return key;
  }

  // 🔗 Get the correct database path
  static Future<String> _getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/secure_notes.db';
  }

  // ✅ Initialize the encrypted database
  static Future<Database> initDB() async {
    final dbPath = await _getDatabasePath();
    final encryptionKey = await _getEncryptionKey();

    return _database ??= await openDatabase(
      dbPath,
      password: encryptionKey, // 🔐 Encrypt the database
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            user_id TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  // ✅ Close the database connection
  static Future<void> closeDB() async {
    await _database?.close();
    _database = null;
  }
}
