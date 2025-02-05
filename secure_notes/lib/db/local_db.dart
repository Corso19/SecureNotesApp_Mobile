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

  static String? getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  static Future<Database> initDB() async {
    final dbPath = await _getDatabasePath();
    final encryptionKey = await _getEncryptionKey();

    return _database ??= await openDatabase(
      dbPath,
      password: encryptionKey,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTables(db);
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL UNIQUE,
        theme_mode TEXT DEFAULT 'system',
        font_size INTEGER DEFAULT 16,
        notifications_enabled INTEGER DEFAULT 1,
        sync_interval INTEGER DEFAULT 5,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // Notes CRUD operations
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
    
    return await db.query('notes',
        where: 'user_id = ?', 
        whereArgs: [userId], 
        orderBy: 'created_at DESC');
  }

  static Future<int> updateNote(int id, String title, String content) async {
    final db = await initDB();
    final userId = getCurrentUserId();
    
    return await db.update(
      'notes',
      {
        'title': title,
        'content': content,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
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

  // Preferences operations
  static Future<Map<String, dynamic>> getPreferences() async {
    final db = await initDB();
    final userId = getCurrentUserId();
    
    final results = await db.query(
      'preferences',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (results.isEmpty) {
      // Create default preferences
      final id = await db.insert('preferences', {
        'user_id': userId,
        'theme_mode': 'system',
        'font_size': 16,
        'notifications_enabled': 1,
        'sync_interval': 5,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      return {
        'id': id,
        'user_id': userId,
        'theme_mode': 'system',
        'font_size': 16,
        'notifications_enabled': 1,
        'sync_interval': 5,
      };
    }

    return results.first;
  }

  static Future<void> updatePreferences(Map<String, dynamic> prefs) async {
    final db = await initDB();
    final userId = getCurrentUserId();

    await db.update(
      'preferences',
      {
        ...prefs,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}