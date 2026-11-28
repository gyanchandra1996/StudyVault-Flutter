import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/note_repo.dart';
import '../models/personal_note.dart';
import '../providers/settings_provider.dart';
import '../services/voice_service.dart';
import '../widgets/formatted_note_content.dart';

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

  void _showAddNoteDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('New Study Note', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 7,
          decoration: const InputDecoration(
            hintText: 'Write note title on first line, then key points or formulas...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                await _noteRepo.addNote(noteText: text);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadNotes();
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _showReadNoteDialog(PersonalNote note, SettingsProvider settings) {
    bool isSpeaking = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580, maxHeight: 740),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.pdfTitle ?? 'Study Note',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                _formatDate(note.updatedAt),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isSpeaking ? Icons.stop_circle : Icons.volume_up_outlined,
                            color: isSpeaking ? Colors.red : Colors.teal,
                          ),
                          tooltip: isSpeaking ? 'Stop Reading' : 'Listen',
                          onPressed: () {
                            if (isSpeaking) {
                              VoiceService.instance.stop();
                              setDialogState(() => isSpeaking = false);
                            } else {
                              setDialogState(() => isSpeaking = true);
                              VoiceService.instance.speak(
                                note.noteText,
                                speechRate: settings.ttsSpeechRate,
                                preferredLocale: settings.ttsPreferredLocale,
                                preferredVoiceName: settings.ttsPreferredVoiceName,
                                onStatusChange: (s) {
                                  if (ctx.mounted && !s) {
                                    setDialogState(() => isSpeaking = false);
                                  }
                                },
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            VoiceService.instance.stop();
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: FormattedNoteContent(
                        data: note.noteText,
                        accentColor: const Color(0xFF1E3A8A),
                        fontSize: 14.5,
                        textColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  if (settings.canEdit)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit Note'),
                            onPressed: () {
                              VoiceService.instance.stop();
                              Navigator.pop(ctx);
                              _showEditNoteDialog(note);
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) => VoiceService.instance.stop());
  }

  void _showEditNoteDialog(PersonalNote note) {
    final textController = TextEditingController(text: note.noteText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Study Note'),
        content: TextField(
          controller: textController,
          maxLines: 7,
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
      floatingActionButton: settings.canEdit
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Add Note'),
              onPressed: _showAddNoteDialog,
            )
          : null,
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
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showReadNoteDialog(note, settings),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          note.pdfId != null ? Icons.picture_as_pdf : Icons.note_alt_outlined,
                                          size: 16,
                                          color: const Color(0xFF6366F1),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            note.pdfTitle ?? 'Study Note',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (note.pdfId != null)
                                          Text(
                                            'Page ${note.pageNumber}',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    FormattedNoteContent(
                                      data: note.noteText,
                                      accentColor: const Color(0xFF1E3A8A),
                                      fontSize: 13.5,
                                      selectable: false,
                                      maxBlocks: 6,
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
                                            TextButton.icon(
                                              style: TextButton.styleFrom(
                                                visualDensity: VisualDensity.compact,
                                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                              ),
                                              icon: const Icon(Icons.chrome_reader_mode_outlined, size: 15),
                                              label: const Text('Read', style: TextStyle(fontSize: 11.5)),
                                              onPressed: () => _showReadNoteDialog(note, settings),
                                            ),
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
