import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/local_db.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

class SyncService {
  static final supabase = Supabase.instance.client;
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true
    )
  );

  static Future<void> syncNotes() async {
    _logger.i('Starting sync...');

    if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
      _logger.w('No connectivity, skipping sync');
      return;
    }

    final userId = LocalDB.getCurrentUserId();
    if (userId == null) {
      _logger.e('No user ID found');
      return;
    }

    try {
      // Get remote notes
      final existingRemoteNotes = 
          await supabase.from('notes').select().eq('user_id', userId);
      _logger.i('Found ${existingRemoteNotes.length} existing remote notes');

      // Get local notes
      final localNotes = await LocalDB.getNotes();
      _logger.i('Found ${localNotes.length} local notes');

      // Push local changes to remote
      for (var note in localNotes) {
        try {
          bool exists = existingRemoteNotes.any((remote) =>
              remote['title'] == note['title'] &&
              remote['content'] == note['content'] &&
              remote['created_at'] == note['created_at']);

          if (!exists) {
            _logger.i('Uploading new note to Supabase');
            await supabase.from('notes').upsert({
              'user_id': userId,
              'title': note['title'],
              'content': note['content'],
              'created_at': note['created_at'],
            });
          } else {
            _logger.i('Note already exists in remote, skipping');
          }
        } catch (e) {
          _logger.e('Error syncing note to remote: $e');
        }
      }

      // Pull remote changes to local
      _logger.i('Syncing ${existingRemoteNotes.length} remote notes to local');
      for (var remoteNote in existingRemoteNotes) {
        try {
          bool exists = localNotes.any((local) =>
              local['title'] == remoteNote['title'] &&
              local['content'] == remoteNote['content'] &&
              local['created_at'] == remoteNote['created_at']);

          if (!exists) {
            _logger.i('Downloading new note from Supabase');
            await LocalDB.addNote(
              remoteNote['title'],
              remoteNote['content'],
            );
          }
        } catch (e) {
          _logger.e('Error syncing note to local: $e');
        }
      }

      // Sync preferences
      await syncPreferences();
      _logger.i('Sync completed successfully');

    } catch (e) {
      _logger.e('Sync failed: $e');
    }
  }

  static Future<void> syncPreferences() async {
    _logger.i('Syncing preferences...');
    
    final userId = LocalDB.getCurrentUserId();
    if (userId == null) {
      _logger.e('No user ID found for preferences sync');
      return;
    }

    try {
      // Check if preferences exist
      final existingPrefs = await supabase
          .from('preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // Get local preferences
      final localPrefs = await LocalDB.getPreferences();
      
      if (existingPrefs == null) {
        // Create new preferences
        await supabase.from('preferences').insert({
          'user_id': userId,
          'theme_mode': localPrefs['theme_mode'],
          'font_size': localPrefs['font_size'],
          'notifications_enabled': localPrefs['notifications_enabled'] == 1,
          'sync_interval': localPrefs['sync_interval'],
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing preferences
        await supabase
          .from('preferences')
          .update({
            'theme_mode': localPrefs['theme_mode'],
            'font_size': localPrefs['font_size'],
            'notifications_enabled': localPrefs['notifications_enabled'] == 1,
            'sync_interval': localPrefs['sync_interval'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      }

      // Get updated remote preferences
      final remotePrefs = await supabase
          .from('preferences')
          .select()
          .eq('user_id', userId)
          .single();

      // Update local preferences
      await LocalDB.updatePreferences({
        'theme_mode': remotePrefs['theme_mode'],
        'font_size': remotePrefs['font_size'],
        'notifications_enabled': remotePrefs['notifications_enabled'] ? 1 : 0,
        'sync_interval': remotePrefs['sync_interval'],
      });

      _logger.i('Preferences sync completed');

    } catch (e) {
      _logger.e('Preferences sync failed: $e');
    }
  }

  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}