import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  static Future<String> _getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/secure_notes.db';
  }

  static Future<Database> initDB() async {
    final dbPath = await _getDatabasePath();
    final encryptionKey = await _getEncryptionKey();

    return _database ??= await openDatabase(
      dbPath,
      password: encryptionKey,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  static String? getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  static Future<int> addNote(String title, String content) async {
    final db = await initDB();
    final userId = getCurrentUserId();
    
    return await db.insert('notes', {
      'user_id': userId,
      'title': title,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
      
    });
  }

  static Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await initDB();
    final userId = getCurrentUserId();
    
    return await db.query(
      'notes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC'
    );
  }

  static Future<int> updateNote(int id, String title, String content) async {
    final db = await initDB();
    final userId = getCurrentUserId();
    
    return await db.update(
      'notes',
      {
        'title': title,
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
        
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  static Future<void> upsertNote(
    int remoteId,
    String title,
    String content,
    String createdAt,
  ) async {
    final db = await initDB();
    final userId = getCurrentUserId();
    
    await db.insert(
      'notes',
      {
        'remote_id': remoteId,
        'user_id': userId,
        'title': title,
        'content': content,
        'created_at': createdAt,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<int> updateRemoteId(int localId, int remoteId) async {
    final db = await initDB();
    return await db.update(
      'notes',
      {
        'remote_id': remoteId,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  static Future<int> deleteNote(int id) async {
    final db = await initDB();
    final userId = getCurrentUserId();
    
    return await db.delete(
      'notes',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  static Future<void> closeDB() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}