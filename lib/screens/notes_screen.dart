import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/note_repo.dart';
import '../models/personal_note.dart';
import '../providers/settings_provider.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteRepo _noteRepo = NoteRepo();
  List<PersonalNote> _notes = [];
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes(showLoading: true);
  }

  Future<void> _loadNotes({String? search, bool showLoading = false}) async {
    if (showLoading || !_hasLoadedOnce) {
      setState(() => _isLoading = true);
    }
    final list = await _noteRepo.getAllNotes(search: search);
    if (!mounted) return;
    setState(() {
      _notes = list;
      _isLoading = false;
      _hasLoadedOnce = true;
    });
  }

  void _showEditNoteDialog(PersonalNote note) {
    final textController = TextEditingController(text: note.noteText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Study Note'),
        content: TextField(
          controller: textController,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (note.id != null && textController.text.trim().isNotEmpty) {
                await _noteRepo.updateNote(note.id!, textController.text.trim());
                Navigator.pop(ctx);
                _loadNotes();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteNote(int id) async {
    await _noteRepo.deleteNote(id);
    _loadNotes();
  }

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consolidated Study Notes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadNotes();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => _loadNotes(search: val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_note, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'No Notes Found',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Notes created inside PDF documents will appear here.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _notes.length,
                        itemBuilder: (ctx, index) {
                          final note = _notes[index];
                          return Card(
                            elevation: 1.5,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.indigo.withOpacity(0.15)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFF6366F1)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          note.pdfTitle ?? 'Document Note',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'Page ${note.pageNumber}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Text(
                                    note.noteText,
                                    style: const TextStyle(fontSize: 15, height: 1.4),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(note.updatedAt),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      Row(
                                        children: [
                                          if (settings.canEdit)
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                              onPressed: () => _showEditNoteDialog(note),
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                            ),
                                          if (settings.canDelete)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                              onPressed: () => _deleteNote(note.id!),
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
