import 'package:sqflite_sqlcipher/sqflite.dart';
import 'local_db.dart';

class PreferencesService {
  static Future<void> savePreference(String key, String value) async {
    final db = await LocalDB.initDB();
    await db.insert(
      'user_preferences',
      {'setting_name': key, 'setting_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getPreference(String key) async {
    final db = await LocalDB.initDB();
    final result = await db.query(
      'user_preferences',
      where: 'setting_name = ?',
      whereArgs: [key],
    );

    if (result.isNotEmpty) {
      return result.first['setting_value'] as String;
    }
    return null;
  }
}
