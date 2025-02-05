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
          final existingNote = existingRemoteNotes
              .where((n) => n['id'] == note['id'])
              .firstOrNull;

          if (existingNote == null) {
            // Insert new note
            await supabase.from('notes').insert({
              'title': note['title'],
              'content': note['content'],
              'user_id': userId,
            });
          } else {
            // Update existing note
            await supabase
                .from('notes')
                .update({
                  'title': note['title'],
                  'content': note['content'],
                })
                .eq('id', existingNote['id'])
                .eq('user_id', userId);
          }
        } catch (e) {
          _logger.e('Error syncing note to remote: $e');
        }
      }

      // Handle deleted notes
      for (var remoteNote in existingRemoteNotes) {
        if (!localNotes.any((local) => local['id'] == remoteNote['id'])) {
          await supabase
              .from('notes')
              .delete()
              .eq('id', remoteNote['id'])
              .eq('user_id', userId);
        }
      }

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
      // Get remote preferences
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
}