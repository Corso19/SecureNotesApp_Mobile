import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/local_db.dart';
import '../services/sync_service.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import '../services/security_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _notes = [];
  Timer? _syncTimer;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    loadNotes();
    _syncTimer = Timer.periodic(
        const Duration(minutes: 1), (_) => SyncService.syncNotes());
    SyncService.syncNotes().then((_) => print('Initial sync complete'));
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> loadNotes() async {
    if (!mounted) return;
    final allNotes = await LocalDB.getNotes();
    setState(() {
      _notes.clear();
      _notes.addAll(allNotes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return ListTile(
            title: Text(note['title']),
            subtitle: Text(note['content']),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Edit'),
                  onTap: () => _editNote(note),
                ),
                PopupMenuItem(
                  child: const Text('Delete'),
                  onTap: () => _deleteNote(note['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createNote() async {
    if (!mounted) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => NoteDialog(),
    );

    if (result != null && mounted) {
      await LocalDB.addNote(result['title']!, result['content']!);
      await SyncService.syncNotes();
      loadNotes();
    }
  }

  Future<void> _editNote(Map<String, dynamic> note) async {
    if (!mounted) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => NoteDialog(
        title: note['title'],
        content: note['content'],
      ),
    );

    if (result != null && mounted) {
      await LocalDB.updateNote(
          note['id'], result['title']!, result['content']!);
      await SyncService.syncNotes();
      loadNotes();
    }
  }

  // Future<void> _deleteNote(int id) async {
  //   await LocalDB.deleteNote(id);
  //   if (mounted) {
  //     await SyncService.syncNotes();
  //     loadNotes();
  //   }
  // }

  Future<void> _deleteNote(int id) async {
    try {
      await LocalDB.deleteNote(id);
      await SyncService.syncNotes(); // Sync with remote
      await loadNotes(); // Refresh list

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Note deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    final navigatorContext = context;
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      navigatorContext,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}

class NoteDialog extends StatefulWidget {
  final String? title;
  final String? content;

  const NoteDialog({super.key, this.title, this.content});

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title == null ? 'New Note' : 'Edit Note'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter content';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'title': SecurityService.sanitizeInput(_titleController.text),
                'content':
                    SecurityService.sanitizeInput(_contentController.text),
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
