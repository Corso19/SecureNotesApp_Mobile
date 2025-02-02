import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalDB {
  static Database? _database;
  static final _secureStorage = FlutterSecureStorage();
  
  static Future<String> _getEncryptionKey() async {
    String? key = await _secureStorage.read(key: 'db_key');
    if (key == null) {
      key = List.generate(32, (i) => (65 + i).toRadixString(16)).join();
      await _secureStorage.write(key: 'db_key', value: key);
    }
    return key;
  }

  static Future<Database> initDB() async {
    final dbPath = await getDatabasesPath() + 'secure_notes.db';
    final encryptionKey = await _getEncryptionKey();

    return _database ??= await openDatabase(
      dbPath,
      password: encryptionKey,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT
          )
        ''');
      },
    );
  }
}
