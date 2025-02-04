import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/local_db.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  static final supabase = Supabase.instance.client;

  static Future<void> syncNotes() async {
    print('Starting sync...');

    if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
      print('No connectivity, skipping sync');
      return;
    }

    final userId = LocalDB.getCurrentUserId();
    if (userId == null) {
      print('No user ID found');
      return;
    }

    try {
      // Get existing remote notes first to check for duplicates
      final existingRemoteNotes =
          await supabase.from('notes').select().eq('user_id', userId);

      print('Found ${existingRemoteNotes.length} existing remote notes');

      // Push local changes to Supabase
      final localNotes = await LocalDB.getNotes();
      print('Found ${localNotes.length} local notes');

      for (var note in localNotes) {
        try {
          // Check if note already exists in remote
          bool exists = existingRemoteNotes.any((remote) =>
              remote['title'] == note['title'] &&
              remote['content'] == note['content'] &&
              remote['created_at'] == note['created_at']);

          if (!exists) {
            final response = await supabase
                .from('notes')
                .upsert({
                  'user_id': userId,
                  'title': note['title'],
                  'content': note['content'],
                  'created_at': note['created_at'],
                })
                .select()
                .single();

            print('Created new note in Supabase: ${response['id']}');
          } else {
            print('Note already exists in remote, skipping');
          }
        } catch (e) {
          print('Error pushing note to Supabase: $e');
          continue;
        }
      }

      // Pull and update local DB
      final remoteNotes =
          await supabase.from('notes').select().eq('user_id', userId);

      print('Syncing ${remoteNotes.length} remote notes to local');

      for (var note in remoteNotes) {
        try {
          // Safe ID conversion handling
          int? noteId;
          if (note['id'] is int) {
            noteId = note['id'];
          } else if (note['id'] is String) {
            noteId = int.tryParse(note['id']);
          }

          if (noteId == null) {
            print('Invalid note ID format: ${note['id']}');
            continue;
          }

          await LocalDB.upsertNote(
              noteId, note['title'], note['content'], note['created_at']);
          print('Synced remote note locally: $noteId');
        } catch (e) {
          print('Error syncing remote note locally: $e');
          continue;
        }
      }
    } catch (e) {
      print('Sync failed: $e');
    }
  }

  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}
